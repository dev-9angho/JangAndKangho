// Firebase Functions (Node.js 환경)에서 사용할 코드입니다.
const functions = require("firebase-functions");
// node-fetch는 API 호출을 위한 라이브러리입니다.
const fetch = require("node-fetch");

// ⚠️ 중요: 여기에 실제 Gemini API 키를 넣으세요.
// "YOUR_GEMINI_API_KEY_HERE"를 발급받은 실제 키로 교체해야 합니다!
const GEMINI_API_KEY = "AIzaSyDQtrgRaKYZK6wPhhJgIpvQLeLXSJGSLiM";
const GEMINI_MODEL = "gemini-2.5-flash-preview-09-2025";
const API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

// Firebase HTTP Callable Function 정의
exports.fetchSleepTips = functions.https.onCall(async (data, context) => {
  // 사용자 인증 확인 (권장됨)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "로그인된 사용자만 접근할 수 있습니다."
    );
  }

  // 1. 시스템 프롬프트 정의
  const systemPrompt = `
당신은 수면 건강 전문가이자 정보 큐레이터입니다.
Google 검색을 활용하여 사용자의 수면 개선에 도움이 될 수 있는
최신 정보를 3개의 기사/팁 형태로 추천하세요.
응답은 반드시 아래 JSON 스키마를 따르는 JSON 문자열이어야 합니다.
`;

  // 2. 응답 스키마 정의 (구조화된 JSON 응답 요청)
  const responseSchema = {
    type: "ARRAY",
    items: {
      type: "OBJECT",
      properties: {
        "title": {
          "type": "STRING",
          "description": "기사의 매력적인 제목입니다.",
        },
        "summary": {
          "type": "STRING",
          "description": "기사 내용을 요약한 50자 이내의 간결한 요약입니다.",
        },
        "url": {
          "type": "STRING",
          "description": "출처가 된 정보의 웹사이트 주소입니다 (AI가 검색한 결과에서 가장 관련 높은 URL을 할당해야 합니다).",
        },
      },
      propertyOrdering: ["title", "summary", "url"],
    },
  };

  const userQuery = "최신 수면 과학, 숙면을 위한 팁, 불면증 치료법 중 핫 토픽을 찾아줘.";
    
  const payload = {
    contents: [{ parts: [{ text: userQuery }] }],
    tools: [{ "google_search": {} }], // Google Search Grounding 활성화
    systemInstruction: { parts: [{ text: systemPrompt }] },
    config: {
      responseMimeType: "application/json", // JSON 응답 요청
      responseSchema: responseSchema,
    },
  };

  try {
    const response = await fetch(API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error(
        `API 호출 실패: ${response.status} - ${response.statusText}`
      );
    }

    const result = await response.json();
    
    // Optional Chaining (?.) 대신 전통적인 && 연산자 사용 (Node.js 호환성)
    const candidate = result.candidates && result.candidates[0];
    const content = candidate && candidate.content;
    const parts = content && content.parts && content.parts[0];
    const jsonText = parts && parts.text;

    if (jsonText) {
      // JSON 문자열을 파싱하여 클라이언트에게 반환
      const parsedJson = JSON.parse(jsonText);
            
      return { success: true, articles: parsedJson };
    } else {
      return {
        success: false,
        error: "AI 응답에서 유효한 JSON을 찾을 수 없습니다.",
      };
    }
  } catch (error) {
    console.error("Firebase Function Error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "AI API 호출 또는 처리 중 오류 발생",
      error.message
    );
  }
});