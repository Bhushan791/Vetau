import dotenv from "dotenv";
dotenv.config();

import mongoose from "mongoose";
import app from "./app.js";
import connectDB from "./db/connection.js";
import fs from "fs";
import path from "path";

// Ensure the temp folder exists (for uploads)
const tempDir = path.join(process.cwd(), "public/temp");
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir, { recursive: true });
  console.log("✅ Created public/temp folder for uploads");
}

const port = process.env.PORT || 8000;

// Connect to MongoDB
connectDB()
  .then(() => {
    app.listen(port, () => {
      console.log(`✅ Server is running at PORT: ${port}`);
    });

    app.on("error", (error) => {
      console.error("⚠ Server ERROR:", error);
      throw error;
    });
  })
  .catch((err) => {
    console.error("❌ Failed MongoDB connection:", err);
  });

// Simple test route
app.get("/", (req, res) => {
  res.send("<h1>Everything is working — GOOD TO GO!</h1>");
});
