// index.js

const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
const dotenv = require('dotenv');
const helmet = require('helmet');
const path = require('path');
const favicon = require('serve-favicon');

dotenv.config();

const app = express();
app.use(helmet());
app.use(morgan('dev'));
app.use(cors());
app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send('APLICAÇÃO NO AR!');
});

app.get('/healthcheck', (req, res) => {
    res.status(200).json({ status: 'UP' });
});

app.listen(port, () => {
    console.log(`Servidor rodando na porta ${port}`);
});
