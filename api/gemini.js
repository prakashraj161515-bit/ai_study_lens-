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
    // Unified OCR + MCQ Task
    prompt = `Extract all readable text from this image exactly as it appears. Then generate 5 MCQs based on the extracted text.
    
Return ONLY valid JSON. No explanation. No markdown blocks outside the JSON.
Format:
{
  "text": "...",
  "mcqs": [
    {
      "question": "...",
      "options": ["A", "B", "C", "D"],
      "answer": "A"
    }
  ]
}`;
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
  const maxRetriesPerModel = 2;

  for (const model of modelsToTry) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    for (let attempt = 1; attempt <= maxRetriesPerModel; attempt++) {
      try {
        const response = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ contents })
        });

        const data = await response.json();
        
        if (response.ok) {
          // Success: Extract text from Gemini response
          let reply = data.candidates?.[0]?.content?.parts?.[0]?.text || "";
          
          // Clean markdown JSON formatting if present
          reply = reply.replace(/```json/g, '').replace(/```/g, '').trim();
          
          return res.status(200).json({ result: reply, model_used: model });
        } else {
          // Failed: save error
          lastErrorMsg = data?.error?.message || "Unknown API Error";
          // If it's a 503 high demand or 429, wait a bit and retry
          if (response.status === 503 || response.status === 429) {
            await new Promise(resolve => setTimeout(resolve, 1500));
            continue; 
          }
          // Break inner loop for other errors to switch model
          break;
        }
      } catch (error) {
        lastErrorMsg = error.message;
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
  }

  // If all models failed, return the last error
  return res.status(500).json({ error: lastErrorMsg });
}
