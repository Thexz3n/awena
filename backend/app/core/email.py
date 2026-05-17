import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging
from app.config import settings

logger = logging.getLogger("uvicorn.error")

def send_reset_email(to_email: str, name: str, token: str) -> bool:
    """Send a password reset email using configured SMTP settings.
    If SMTP settings are not provided, it logs to the console as a fallback.
    """
    subject = "Awêna - Reset Your Password / کۆدی گۆڕینی وشەی نهێنی"
    
    # Render beautiful responsive HTML email supporting bilingual EN/KU
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                background-color: #0f111a;
                color: #e2e8f0;
                margin: 0;
                padding: 40px 20px;
            }}
            .card {{
                max-width: 500px;
                margin: 0 auto;
                background-color: #1a1d30;
                border-radius: 16px;
                border: 1px solid rgba(255, 255, 255, 0.08);
                padding: 32px;
                box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
                text-align: center;
            }}
            .logo {{
                font-size: 24px;
                font-weight: 800;
                background: linear-gradient(135deg, #00f2fe 0%, #4facfe 100%);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                margin-bottom: 24px;
            }}
            h2 {{
                color: #ffffff;
                margin-top: 0;
                font-size: 20px;
            }}
            .token-box {{
                background-color: rgba(255, 255, 255, 0.05);
                border: 1px dashed rgba(255, 255, 255, 0.15);
                border-radius: 12px;
                padding: 16px;
                font-size: 32px;
                font-weight: 800;
                letter-spacing: 6px;
                color: #00f2fe;
                margin: 24px 0;
                font-family: monospace;
            }}
            p {{
                font-size: 14px;
                line-height: 1.6;
                color: #a0aec0;
            }}
            .footer {{
                margin-top: 32px;
                font-size: 11px;
                color: #718096;
                border-top: 1px solid rgba(255, 255, 255, 0.08);
                padding-top: 16px;
            }}
            .rtl {{
                direction: rtl;
                text-align: right;
            }}
        </style>
    </head>
    <body>
        <div class="card">
            <div class="logo">Awêna</div>
            
            <div class="rtl">
                <h2>سڵاو {name} 👋</h2>
                <p>داواکارییەکت پێگەیشتووە بۆ گۆڕینی وشەی نهێنی هەژمارەکەت. تکایە ئەم کۆدە بەکاربهێنە بۆ تەواوکردنی پرۆسەکە:</p>
            </div>
            
            <div class="token-box">{token}</div>
            
            <div>
                <h2>Hello {name} 👋</h2>
                <p>We received a request to reset your password. Please use the verification code above to complete your reset:</p>
            </div>
            
            <p class="footer">
                If you did not request this, you can safely ignore this email.<br>
                ئەگەر تۆ ئەم داواکارییە کۆدە پێشکەش نەکردووە، دەتوانیت پشتگوێی بخەیت.
            </p>
        </div>
    </body>
    </html>
    """

    text_content = f"""
    Hello {name},
    We received a request to reset your password.
    Your reset verification code is: {token}
    
    سڵاو {name},
    کۆدی نوێکردنەوەی وشەی نهێنیەکەت بریتییە لە: {token}
    """

    # Print to console for development convenience
    logger.info("==================================================================")
    logger.info(f"🔑 PASSWORD RESET TOKEN FOR: {to_email}")
    logger.info(f"👉 VERIFICATION CODE: {token}")
    logger.info("==================================================================")

    # Check if SMTP is configured
    if not settings.SMTP_HOST or not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        logger.warning("⚠️ SMTP settings are not configured in your .env. Real email was not sent.")
        return False

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = settings.SMTP_FROM or settings.SMTP_USER
        msg["To"] = to_email

        msg.attach(MIMEText(text_content, "plain", "utf-8"))
        msg.attach(MIMEText(html_content, "html", "utf-8"))

        server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT)
        server.ehlo()
        server.starttls()
        server.ehlo()
        server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        server.sendmail(msg["From"], [to_email], msg.as_string())
        server.close()

        logger.info(f"📧 Real password reset email sent successfully to {to_email}!")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to send real password reset email: {str(e)}")
        return False
