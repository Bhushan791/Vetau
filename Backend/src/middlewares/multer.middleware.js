import express from "express";
import { upload } from "../middlewares/multer.js";

const router = express.Router();

// Single file upload (e.g., profile image)
router.post("/upload-profile", upload.single("profileImage"), (req, res) => {
    res.json({ file: req.file });
});

// Multiple files upload (e.g., item images in Lost/Found posts)
router.post("/upload-items", upload.array("images", 5), (req, res) => {
    res.json({ files: req.files });
});
