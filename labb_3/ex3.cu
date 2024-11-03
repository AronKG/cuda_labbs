#include <jetson-utils/videoSource.h>  // Include the header for video source handling
#include <jetson-utils/videoOutput.h>  // Include the header for video output handling

// CUDA kernel function to convert an RGB image to grayscale
__global__ void rgb2grayKernel(uchar4* image, uchar4* output, int width, int height)
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
        
        // Set the RGB values of the output pixel to the grayscale value
        output[i].x = gray; // Red channel
        output[i].y = gray; // Green channel
        output[i].z = gray; // Blue channel
        // The alpha channel (output[i].w) remains unchanged
    }
}

int main(int argc, char** argv)
{
    // Create input and output streams for video handling
    videoSource* input = videoSource::Create(argc, argv, ARG_POSITION(0));
    videoOutput* output = videoOutput::Create(argc, argv, ARG_POSITION(1));
    videoOutput* output2 = videoOutput::Create(argc, argv, ARG_POSITION(2)); // Create a second output for grayscale

    // Check if the input video source was successfully created
    if (!input)
        return 0; // Exit if input cannot be created

    // Allocate device memory for the output image
    uchar4* d_output;
    size_t imageSize = input->GetWidth() * input->GetHeight() * sizeof(uchar4);
    cudaMalloc((void**)&d_output, imageSize); // Allocate memory on the GPU for output image

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
                continue; // If timeout, skip to the next iteration
            break; // End of stream (EOS), break the loop
        }

        // Launch the kernel to convert the image to grayscale
        rgb2grayKernel<<<16, 1024>>>(image, d_output, input->GetWidth(), input->GetHeight());

        // If the primary output stream is valid, render the original image
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

        // If the second output stream is valid, render the grayscale image
        if (output2 != NULL)
        {
            output2->Render(d_output, input->GetWidth(), input->GetHeight());

            // Update the status bar for the second output stream
            char str[256];
            sprintf(str, "Grayscale Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
                    input->GetHeight(), output2->GetFrameRate());
            output2->SetStatus(str);

            // Check if the user has quit the streaming
            if (!output2->IsStreaming())
                break; // Exit the loop if not streaming
        }
    }

    // Free allocated device memory
    cudaFree(d_output); // Release the allocated GPU memory for the output image
}
