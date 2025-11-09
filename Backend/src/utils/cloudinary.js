import  {v2 as cloudinary} from "cloudinary"

import fs from "fs"   //files system 


const uploadToCloudinary =   async (localFilePath)   => {
cloudinary.config({ 
        cloud_name: process.env.CLOUDINARY_CLOUD_NAME ,

        api_key:  process.env.CLOUDINARY_API_KEY, 

        api_secret: process.env.CLOUDINARY_API_SECRET
    });


    try { 

        if(!localFilePath) return null

        //upload file to cloudinary
     const response = await cloudinary.uploader.upload(localFilePath, { resource_type: "auto"} )



         fs.unlinkSync(localFilePath) ;

      

        return response;

    }
    catch(Error)  {

        fs.unlinkSync(localFilePath)  //remove the locally saved temp file as the upload operation got failed




    }
}



const deleteFromCloudinary =  async(publicId) => { 


    try { 
        if(!publicId) return null

        const result = await cloudinary.uploader.destroy(publicId)

        return result 
    }catch(error) { 
        console.log("Error deleting from cloudinary", error) ; 
    }
}
export { uploadToCloudinary, deleteFromCloudinary};