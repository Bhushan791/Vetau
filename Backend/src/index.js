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

// Firebase initializer
import { initializeFirebase } from "./config/firebase.js";

// ADD: Seed Admin utility
import { seedAdmin } from "./utils/seedAdmin.js";

// ADD: Import seed database function
import seedDatabase from "./tempseed.js";

// Ensure temp folder exists
const tempDir = path.join(process.cwd(), "public/temp");
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir, { recursive: true });
  console.log("Created public/temp folder");
}

const port = process.env.PORT || 8000;

// Connect to DB
connectDB()
  .then(async () => {
    // Initialize Firebase
    initializeFirebase();

    // Run admin seeding
    await seedAdmin();

    // Run database seeding
    console.log("\n🌱 Seeding database with test data...");
    await seedDatabase();

    // HTTP server for Socket.IO
    const httpServer = createServer(app);

    // Init socket
    initializeSocket(httpServer);

    // Start server
    httpServer.listen(port, () => {
      console.log(`Server running on PORT: ${port}`);
      console.log("Socket.io ready");
      console.log("Firebase initialized");
    });

    app.on("error", (error) => {
      console.error("Server ERROR:", error);
      throw error;
    });
  })
  .catch((err) => {
    console.error("Failed MongoDB connection:", err);
  });

// Resolve __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Root test route
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "serverWorkingFlag.html"));
});