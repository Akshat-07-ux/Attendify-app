const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

const gmailEmail = 'akshatbhagat359@gmail.com';
const gmailPassword = 'abcdEf2002@Ranchi';

const mailTransport = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

exports.sendAdminEmail = functions.firestore
  .document('leave_requests/{requestId}')
  .onCreate((snap, context) => {
    const newValue = snap.data();
    const mailOptions = {
      from: '"Leave Request" <noreply@firebase.com>',
      to: 'akshatbhagat359@gmail.com',
      subject: 'New Leave Request',
      text: `${newValue.name} has applied for a leave. Kindly check dashboard.`,
    };

    return mailTransport.sendMail(mailOptions);
  });