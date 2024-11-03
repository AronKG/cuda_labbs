#include <jetson-utils/videoSource.h>  // Include the header for video source handling
#include <jetson-utils/videoOutput.h>  // Include the header for video output handling

// CUDA kernel function to convert an RGB image to grayscale
__global__ void rgb2grayKernel(uchar4* image, int width, int height)
{ 
    // Calculate the total number of pixels in the image
    long int size = width * height; 
    // Calculate the index of the current thread
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    // Calculate the stride for accessing pixels in a loop
    int stride = blockDim.x * gridDim.x;
    
    // Loop over the image pixels in strides to ensure all pixels are processed
    for (int i = index; i < size; i += stride) {
        // Calculate the grayscale value using the luminosity method
        unsigned char gray = (0.299 * image[i].x) + (0.587 * image[i].y) + (0.114 * image[i].z); 
        
        // Set the RGB values of the pixel to the grayscale value
        image[i].x = gray; // Red channel
        image[i].y = gray; // Green channel
        image[i].z = gray; // Blue channel
        // Alpha channel (image[i].w) is unchanged
    }
}

int main(int argc, char** argv)
{
    // Create input/output streams for the video source and output
    videoSource* input = videoSource::Create(argc, argv, ARG_POSITION(0));
    videoOutput* output = videoOutput::Create(argc, argv, ARG_POSITION(1));
    
    // Check if the input video source was successfully created
    if (!input)
        return 0; // Exit if input cannot be created

    // Capture/display loop to continuously process frames
    while (true)
    {
        uchar4* image = NULL; // Pointer to the image buffer
        int status = 0; // Status variable for video source (OK, TIMEOUT, EOS, ERROR)
        
        // Capture an image from the video source with a 1000ms timeout
        if (!input->Capture(&image, 1000, &status)) 
        {
            // Check if the capture timed out and continue the loop if so
            if (status == videoSource::TIMEOUT)
                continue;
            break; // End of stream (EOS), break the loop
        }

        // Launch the kernel to convert the image to grayscale
        rgb2grayKernel<<<16, 1024>>>(image, input->GetWidth(), input->GetHeight());

        // If the output stream is valid, render the processed image
        if (output != NULL)
        {
            output->Render(image, input->GetWidth(), input->GetHeight());
            // Update the status bar with the current frame dimensions and FPS
            char str[256];
            sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
                    input->GetHeight(), output->GetFrameRate());
            output->SetStatus(str);
            // Check if the user has quit the streaming
            if (!output->IsStreaming())
                break; // Exit the loop if not streaming
        }
    }
}
