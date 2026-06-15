import express from "express";

const router = express.Router();

router.get('/', async (req, res) => {
    res.json({
        "author" : "Yassir Driuch",
        "title" : "dotNovi - DevOps",
        "description" : "DevOps Assignment application"
    });
});

export default router;