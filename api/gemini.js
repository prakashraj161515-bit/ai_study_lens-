export default async function handler(req, res) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'API key not configured on server' });
  }

  const { text, imageBase64, isExplanation, isMcq, count, difficulty } = req.body;

  let prompt = text || "";
  let contents = [];

  if (imageBase64) {
    // OCR Task: Extract text from image
    prompt = "Extract all readable text from this image exactly as it appears. Do not add formatting or markdown. If there is no text, reply with 'No text found'.";
    contents = [
      {
        parts: [
          { text: prompt },
          { inline_data: { mime_type: "image/jpeg", data: imageBase64 } }
        ]
      }
    ];
  } else if (isMcq) {
    // MCQ Generation
    prompt = `Generate ${count || 3} MCQs for the following topic: ${text}\nDifficulty: ${difficulty || 'Medium'}\n\nReturn ONLY a JSON array with this exact structure:\n[\n  {\n    "question": "The question text",\n    "options": ["Option A", "Option B", "Option C", "Option D"],\n    "answer": "The exact string of the correct option"\n  }\n]\nDo NOT include any explanations or markdown formatting outside the JSON.`;
    contents = [{ parts: [{ text: prompt }] }];
  } else {
    // Normal QnA
    const systemInstruction = isExplanation 
        ? "Provide a detailed step-by-step explanation." 
        : "You are a smart study assistant. Respond based on question complexity. Provide only direct factual answers for simple questions, and short explanations for complex ones.";
    prompt = `INSTRUCTION: ${systemInstruction}\n\nQUESTION: ${text}`;
    contents = [{ parts: [{ text: prompt }] }];
  }

  // Models to try in order of preference
  const modelsToTry = [
    "gemini-3.1-flash-lite",
    "gemini-2.5-flash-lite"
  ];

  let lastErrorMsg = "Gemini API Error";

  for (const model of modelsToTry) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents })
      });

      const data = await response.json();
      
      if (response.ok) {
        // Success: Extract text from Gemini response
        const reply = data.candidates?.[0]?.content?.parts?.[0]?.text || "";
        return res.status(200).json({ result: reply, model_used: model });
      } else {
        // Failed: save error and try next model
        lastErrorMsg = data?.error?.message || "Unknown API Error";
      }
    } catch (error) {
      lastErrorMsg = error.message;
    }
  }

  // If all models failed, return the last error
  return res.status(500).json({ error: lastErrorMsg });
}
