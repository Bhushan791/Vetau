import dotenv from "dotenv";
dotenv.config();

import mongoose from "mongoose";
import app from "./app.js";
import connectDB from "./db/connection.js";
import fs from "fs";
import path from "path";
import { createServer } from "http";
import { initializeSocket } from "./socket/socket.js";
import { fileURLToPath } from "url";
import { initializeFirebase } from "./config/firebase.js";

// Resolve __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Ensure temp folder exists
const tempDir = path.join(process.cwd(), "public/temp");
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir, { recursive: true });
  console.log("Created public/temp folder");
}

// Use dynamic port for Fly; fallback to 8000 for local/Render
const PORT = process.env.PORT || 8000;

// Connect to DB
connectDB()
  .then(async () => {
    // Initialize Firebase
    initializeFirebase();

    // Create HTTP server for Socket.IO
    const httpServer = createServer(app);

    // Initialize Socket.IO
    initializeSocket(httpServer);

    // Start server
    httpServer.listen(PORT, "0.0.0.0", () => {
      console.log(`Server running on PORT: ${PORT}`);
      console.log("Socket.io ready");
      console.log("Firebase initialized");
    });

    // Handle app errors
    app.on("error", (error) => {
      console.error("Server ERROR:", error);
      throw error;
    });
  })
  .catch((err) => {
    console.error("Failed MongoDB connection:", err);
  });

// Serve root HTML file
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "serverWorkingFlag.html"));
});
