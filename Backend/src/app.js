import express from "express" 
import cors from "cors"
import cookieParser from "cookie-parser" 
import { swaggerUi, swaggerSpec } from "../swagger.js";
import passport from "./config/passport.js";  
import { errorHandler } from "./middlewares/errorHandler.middleware.js";

//express initialization
const app = express();


//builtin middlewares 
app.use(cors({
    origin: process.env.CORS_ORIGIN,
credentials: true
}))  
app.use(express.json({limit:"16kb"}))
app.use(express.urlencoded({extended:true, limit:"16kb"}))
app.use(express.static("public"))
app.use(cookieParser())

//google o auth 
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
import commentRouter from "./routes/comment.routes.js";

//routes decleration 
app.use("/api/v1/users", userRouter)
app.use("/api/v1/categories", categoryRouter); 
app.use("/api/v1/posts", postRouter); 
app.use("/api/v1/claims", claimRoutes);
app.use("/api/v1/chats", chatRouter);
app.use("/api/v1/messages", messageRouter);
app.use("/api/v1/comments", commentRouter);








//Error handler withjson response
app.use(errorHandler);
export default app