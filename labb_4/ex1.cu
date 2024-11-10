#include <jetson-utils/videoSource.h>
#include <jetson-utils/videoOutput.h>
#include <stdio.h>

// Kernel to convert RGB image to grayscale
__global__ void rgb2grayKernel(uchar4* image, uchar4* output, int width, int height)
{ 
    // Calculate total image size
    long int size = width * height; 

    // Determine pixel index and stride for parallel processing
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;

    // Loop over the pixels handled by this thread
    for (int i = index; i < size; i += stride) {
        // Compute grayscale intensity using weighted average of RGB values
        unsigned char gray = (0.299 * image[i].x) + (0.587 * image[i].y) + (0.114 * image[i].z); 
        output[i].x = gray; 
        output[i].y = gray; 
        output[i].z = gray; 
    }
}

// Kernel to calculate histogram for grayscale image
__global__ void calcHistogramKernel(uchar4* d_output, int* histogram, int width, int height)
{ 
    // Calculate total image size
    long int size = width * height; 

    // Determine pixel index and stride for parallel processing
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;

    // Initialize histogram bins to zero (one bin per thread, up to 256 threads)
    if (index < 256) {
        histogram[index] = 0; 
    }

    // Synchronize threads to ensure histogram initialization is complete
    __syncthreads(); 

    // Update histogram by counting grayscale intensities
    for (int i = index; i < size; i += stride) {
        unsigned char gray = d_output[i].x; 
        atomicAdd(&histogram[gray], 1); // Atomic addition to avoid race conditions
    }
}

int main(int argc, char** argv)
{
    // Create input and output video streams
    videoSource* input = videoSource::Create(argc, argv, ARG_POSITION(0));
    videoOutput* output = videoOutput::Create(argc, argv, ARG_POSITION(1));
    videoOutput* output2 = videoOutput::Create(argc, argv, ARG_POSITION(1));

    if (!input)
        return 0;

    uchar4* d_output; // Output for grayscale image on device
    size_t imageSize = input->GetWidth() * input->GetHeight() * sizeof(uchar4);

    // Allocate memory for grayscale image and histogram on device
    cudaMalloc((void**)&d_output, imageSize);
    int* histogram; 
    cudaMalloc(&histogram, 256 * sizeof(int));
    int host_histo[256]; // Array to store histogram on host

    // Capture and display loop
    while (true)
    {
        uchar4* image = NULL; // Pointer to captured image
        int status = 0; // Status variable for videoSource capture
        if (!input->Capture(&image, 1000, &status)) // Capture image with 1000ms timeout
        {
            if (status == videoSource::TIMEOUT)
                continue;
            break; // End of stream or error
        }

        // Launch grayscale conversion and histogram calculation kernels
        rgb2grayKernel<<<16, 1024>>>(image, d_output, input->GetWidth(), input->GetHeight());
        calcHistogramKernel<<<16, 1024>>>(d_output, histogram, input->GetWidth(), input->GetHeight());

        // Copy histogram from device to host
        cudaMemcpy(host_histo, histogram, 256 * sizeof(int), cudaMemcpyDeviceToHost);

        // Sum all histogram values to verify total pixel count (sanity check)
        int sum = 0; 
        for (int i = 0; i < 256; i++) {
            sum += host_histo[i]; 
        }
        printf("%d\n", sum); // Print the sum for verification

        // Display original image
        if (output != NULL) {
            output->Render(image, input->GetWidth(), input->GetHeight());

            // Update status bar with resolution and frame rate
            char str[256];
            sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
            input->GetHeight(), output->GetFrameRate());
            output->SetStatus(str);
            if (!output->IsStreaming()) // Check if the user quit
                break;
        }

        // Display grayscale image
        if (output2 != NULL) {
            output2->Render(d_output, input->GetWidth(), input->GetHeight());

            // Update status bar with resolution and frame rate
            char str[256];
            sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
            input->GetHeight(), output->GetFrameRate());
            output->SetStatus(str);
            if (!output->IsStreaming()) // Check if the user quit
                break;
        }
    }
}
