import dotenv from "dotenv" 
dotenv.config() ; 
import mongoose  from "mongoose"; 
import app from "./app.js";
import connectDB from "./db/connection.js";

const port = process.env.PORT;

connectDB()
.then(()=>{ 
    app.listen(port, ()=>{

        console.log('Server is running at PORT:',port) ;
    })

    app.on("error", (error)=> { 
        console.log("ERROR:", error)
        throw error

    })
})
.catch((err)=> { 
    console.log("Failed connection", err) 

}) 

