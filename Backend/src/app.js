import express from "express" 
import cors from "cors"
import cookieParser from "cookie-parser" 
import { swaggerUi, swaggerSpec } from "../swagger.js";
import passport from "./config/passport.js";  

import { errorHandler } from "./middlewares/errorHandler.middleware.js";
const app = express();



app.use(cors({
    origin: process.env.CORS_ORIGIN,
credentials: true
}))  
app.use(express.json({limit:"16kb"}))
app.use(express.urlencoded({extended:true, limit:"16kb"}))
app.use(express.static("public"))
app.use(cookieParser())

app.use(passport.initialize()); //o auth initialiser
//swaggerapi
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));



//routes denifitions
//routes import
import userRouter from './routes/user.routes.js'
import categoryRouter from './routes/category.routes.js'
import postRouter from './routes/post.routes.js'
import claimRoutes from "./routes/claim.routes.js";
import chatRouter from "./routes/chat.routes.js";
import messageRouter from "./routes/message.routes.js";

//routes decleration 
app.use("/api/v1/users", userRouter)
app.use("/api/v1/categories", categoryRouter); 
app.use("/api/v1/posts", postRouter); 
app.use("/api/v1/claims", claimRoutes);
app.use("/api/v1/chats", chatRouter);
app.use("/api/v1/messages", messageRouter);


































//Error handler withjson response
app.use(errorHandler);
export default app