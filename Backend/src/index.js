import dotenv from "dotenv";
dotenv.config();

import mongoose from "mongoose";
import app from "./app.js";
import connectDB from "./db/connection.js";
import fs from "fs";
import path from "path";
import { createServer } from "http";
import { initializeSocket } from "./socket/socket.js";

// 🔥 Add Firebase initializer
import { initializeFirebase } from "./config/firebase.js";

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
    // 🔥 Initialize Firebase BEFORE starting the server
    initializeFirebase();

    // Use HTTP server to enable socket.io
    const httpServer = createServer(app);

    // Initialize socket.io
    initializeSocket(httpServer);

    // Start server
    httpServer.listen(port, () => {
      console.log(`Server is running at PORT: ${port}`);
      console.log("🔌 Socket.io ready");
      console.log("🔥 Firebase initialized");
    });

    app.on("error", (error) => {
      console.error("⚠ Server ERROR:", error);
      throw error;
    });
  })
  .catch((err) => {
    console.error("❌Failed MongoDB connection:", err);
  });


//server working flag
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Simple test route
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "serverWorkingFlag.html"));
});
