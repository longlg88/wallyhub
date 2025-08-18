const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { Resend } = require('resend');
const axios = require('axios');

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();
db.settings({ databaseId: 'wallydb' });

// Slack 에러 알림 함수
async function sendSlackError(functionName, error, context = {}) {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  if (!webhookUrl) return;
  
  const errorColor = '#ff0000'; // 빨간색
  const timestamp = new Date().toISOString();
  
  const slackMessage = {
    username: 'Firebase Functions Bot',
    icon_emoji: ':fire:',
    attachments: [{
      color: errorColor,
      title: `🚨 Firebase Functions 에러 발생`,
      fields: [
        {
          title: 'Function',
          value: functionName,
          short: true
        },
        {
          title: 'Timestamp',
          value: timestamp,
          short: true
        },
        {
          title: 'Error Message',
          value: `\`\`\`${error.message}\`\`\``,
          short: false
        }
      ],
      footer: 'Wally Firebase Functions',
      ts: Math.floor(Date.now() / 1000)
    }]
  };

  // 추가 컨텍스트가 있으면 필드에 추가
  if (Object.keys(context).length > 0) {
    slackMessage.attachments[0].fields.push({
      title: 'Context',
      value: `\`\`\`${JSON.stringify(context, null, 2)}\`\`\``,
      short: false
    });
  }
  
  try {
    await axios.post(webhookUrl, slackMessage, {
      timeout: 5000,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  } catch (slackError) {
    console.warn('Slack 알림 전송 실패:', slackError.message);
  }
}

// 6자리 인증번호 생성
function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// 이메일 발송 Function
exports.sendVerificationEmail = onCall(async (request) => {
  const { email } = request.data;
  
  if (!email) {
    throw new HttpsError('invalid-argument', 'Email is required');
  }
  
  try {
    // Runtime에서 Resend 초기화
    const resend = new Resend(process.env.RESEND_API_KEY);
    // 6자리 인증번호 생성
    const verificationCode = generateVerificationCode();
    
    // Firestore에 인증번호 저장 (5분 만료)
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5분 후
    
    await db.collection('email_verifications').doc(email).set({
      code: verificationCode,
      email: email,
      expiresAt: expiresAt,
      createdAt: new Date(),
      verified: false
    });
    
    // HTML 이메일 템플릿 (관리자용)
    const htmlContent = `
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Wally 관리자 알림</title>
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
      <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
        <h1 style="margin: 0; font-size: 28px;">🎓 Wally 관리자</h1>
        <p style="margin: 10px 0 0 0; font-size: 18px;">교사 인증 요청</p>
      </div>
      
      <div style="background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px;">
        <h2 style="color: #495057; margin-bottom: 20px;">새로운 교사 인증 요청</h2>
        
        <div style="background: white; border: 2px solid #007bff; border-radius: 8px; padding: 25px; margin: 25px 0;">
          <p style="font-size: 16px; margin-bottom: 15px;"><strong>요청자 이메일:</strong></p>
          <p style="font-size: 18px; color: #007bff; margin-bottom: 20px;">${email}</p>
          
          <p style="font-size: 14px; color: #6c757d; margin-bottom: 10px;">생성된 인증번호</p>
          <div style="font-size: 32px; font-weight: bold; color: #495057; letter-spacing: 4px; font-family: 'SF Mono', Monaco, monospace;">
            ${verificationCode}
          </div>
        </div>
        
        <div style="background: #d1ecf1; border: 1px solid #bee5eb; border-radius: 5px; padding: 15px; margin: 20px 0;">
          <p style="color: #0c5460; margin: 0; font-size: 14px;">
            ℹ️ 이 인증번호는 <strong>5분</strong> 후에 자동 만료됩니다.
          </p>
        </div>
        
        <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0;">
          <p style="color: #856404; margin: 0; font-size: 14px;">
            📱 사용자가 앱에서 위 인증번호를 입력하면 인증이 완료됩니다.
          </p>
        </div>
        
        <p style="color: #6c757d; font-size: 14px; margin-top: 25px;">
          시간: ${new Date().toLocaleString('ko-KR')}
        </p>
      </div>
      
      <div style="text-align: center; padding: 20px; color: #6c757d; font-size: 12px;">
        <p>© 2024 Wally Team - 관리자 알림 시스템</p>
      </div>
    </body>
    </html>
    `;
    
    // Resend로 이메일 발송 (개발용 - 모든 요청을 소유자 이메일로 리다이렉트)
    const testEmail = 'rozen8831@gmail.com'; // API 키 소유자 이메일
    const emailResponse = await resend.emails.send({
      from: 'Wally Team <onboarding@resend.dev>',
      to: [testEmail],
      subject: `🎓 [Wally 관리자] 교사 인증 요청 - ${email}`,
      html: htmlContent
    });
    
    console.log('✅ Resend 이메일 발송 성공:', emailResponse);
    
    // 프로덕션에서는 인증번호를 반환하지 않음
    return {
      success: true,
      message: '인증번호가 이메일로 전송되었습니다.'
    };
    
  } catch (error) {
    const errorContext = {
      email: email,
      timestamp: new Date().toISOString()
    };
    
    console.error('❌ EMAIL_SEND_ERROR:', error);
    
    // Slack으로 에러 알림 전송
    await sendSlackError('sendVerificationEmail', error, errorContext);
    
    throw new HttpsError('internal', 'Failed to send verification email');
  }
});


// 인증번호 확인 Function
exports.verifyEmailCode = onCall(async (request) => {
  const { email, code } = request.data;
  
  if (!email || !code) {
    throw new HttpsError('invalid-argument', 'Email and code are required');
  }
  
  try {
    // Firestore에서 인증번호 확인
    const docRef = db.collection('email_verifications').doc(email);
    const doc = await docRef.get();
    
    if (!doc.exists) {
      throw new HttpsError('not-found', 'Verification code not found');
    }
    
    const data = doc.data();
    const now = new Date();
    
    // 만료 시간 확인
    if (data.expiresAt.toDate() < now) {
      // 만료된 문서 삭제
      await docRef.delete();
      throw new HttpsError('deadline-exceeded', 'Verification code expired');
    }
    
    // 인증번호 확인
    if (data.code !== code) {
      throw new HttpsError('invalid-argument', 'Invalid verification code');
    }
    
    // 인증 완료 표시
    await docRef.update({
      verified: true,
      verifiedAt: new Date()
    });
    
    console.log('✅ 이메일 인증 성공:', email);
    
    return {
      success: true,
      message: '이메일 인증이 완료되었습니다.'
    };
    
  } catch (error) {
    const errorContext = {
      email: email,
      code: code,
      timestamp: new Date().toISOString()
    };
    
    console.error('❌ 인증번호 확인 실패:', error);
    
    // Slack으로 에러 알림 전송 (심각한 에러만)
    if (error.code !== 'invalid-argument' && error.code !== 'not-found') {
      await sendSlackError('verifyEmailCode', error, errorContext);
    }
    
    throw error; // Firebase Functions 에러를 그대로 전달
  }
});