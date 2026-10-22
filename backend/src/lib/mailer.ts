import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT),
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

export const sendResetEmail = async (email: string, code: string) => {
  await transporter.sendMail({
    from: '"Ride Booking" <no-reply@ridebooking.com>',
    to: email,
    subject: 'Your Password Reset Code',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h2>Password Reset</h2>
        <p>You requested to reset your password. Here is your 6-digit verification code:</p>
        <h1 style="color: #1E3A8A; letter-spacing: 5px;">${code}</h1>
        <p>This code expires in 15 minutes. If you didn't request this, please ignore this email.</p>
      </div>
    `,
  });
};