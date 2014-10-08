// require install next modules:
// npm install -g nodemailer nodemailer-smtp-transport
var nodemailer = require('nodemailer');
var smtpTransport = require('nodemailer-smtp-transport');

var transporter = nodemailer.createTransport(smtpTransport({
 host: 'localhost',
    port: 25,
    ignoreTLS: false,
    tls: {rejectUnauthorized: false},
    requiresAuth: false
 }));
var mailOptions = {
    from: 'god@isd.dp.ua', // sender address
    to: 'dvac@isd.dp.ua', // list of receivers
    subject: 'FUCK the system! Yoba!', // Subject line
    text: 'So where the fuck you at? \nPunk, shut the fuck up and back the fuck up \nWhile we fuck this track up', // plaintext body
};


transporter.sendMail(mailOptions, function(error, info){
    if(error){
        console.log('Sendmail error: ' + error);
    }else{
        console.log('Message sent: ' + info.response);
    }
});
