import express from 'express'
import {collectDefaultMetrics, Counter, Gauge, Histogram, register} from 'prom-client';

const router = express.Router();

// Standaard metrics: CPU, memory, event loop
collectDefaultMetrics();

// Custom counter
const httpRequests = new Counter({
    name: 'http_requests_total',
    help: 'Total HTTP requests',
    labelNames: ['method', 'path', 'status']
});

// Custom histogram
const httpDuration = new Histogram({
    name: 'http_request_duration_seconds',
    help: 'HTTP request duration in seconds',
    labelNames: ['method', 'path'],
    buckets: [0.01, 0.05, 0.1, 0.5, 1, 5]
});

const activeConnections = new Gauge({
    name: 'http_active_connections',
    help: 'Number of HTTP requests currently being processed',
});



router.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});

router.use((req, res, next) => {
    const endTimer = httpDuration.startTimer();

    res.on('finish', () => {
        const route = req.route ? `${req.baseUrl}${req.route.path}` : req.path;
        const labels = {
            method: req.method,
            path: route,
            status: String(res.statusCode),
        };
        httpRequests.inc(labels);
        endTimer({method: req.method, path: route});
        activeConnections.dec();

    });
    next();
})


export default router;