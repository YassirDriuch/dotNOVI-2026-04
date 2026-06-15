import express from 'express';
import { healthCheck } from '../db.js';

const router = express.Router();

/**
 * GET /health
 * Health check endpoint for monitoring and load balancers
 */
router.get('/', async (req, res) => {
  try {
    const dbHealthy = await healthCheck();

    const health = {
      status: dbHealthy ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      database: dbHealthy ? 'connected' : 'disconnected',
    };

    const statusCode = dbHealthy ? 200 : 503;
    res.status(statusCode).json(health);
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message,
    });
  }
});

export default router;
