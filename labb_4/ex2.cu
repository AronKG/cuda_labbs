
#include <jetson-utils/videoSource.h>
#include <jetson-utils/videoOutput.h>
#include <stdio.h> 
__global__ void rgb2grayKernel(uchar4* image, uchar4* output, int width, int height)
{ 
    
    long int size = width*height; 
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < size; i += stride) {
    
        unsigned char gray = (0.299*image[i].x) + (0.587*image[i].y) + (0.114*image[i].z); 
        output[i].x  = gray; 
        output[i].y = gray; 
        output[i].z = gray; 
    }

}

__global__ void calcHistogramKernel(uchar4* d_output, int* histogram, int width, int height)
{ 
    
    long int size = width*height; 
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;
 
    if(index < 256)
    {
        histogram[index]= 0; 
    }

    __syncthreads(); 
    
    for (int i = index; i < size; i += stride) {
    
        unsigned char gray = d_output[i].x; 
        atomicAdd(&histogram[gray], 1);
    }

}

__global__ void plotHistogramKernel(uchar4* image, int* histogram, int width, int height, int max_freq)
    {
        int index = blockIdx.x * blockDim.x + threadIdx.x;
        uchar4 white_pixel = make_uchar4(255, 255, 255, 255);
        uchar4 black_pixel = make_uchar4(0, 0, 0, 255);

        if (index < 256)
        {
            int freq = histogram[index] * 256 / max_freq;
            for (int i = 0; i < 256; i++)
            {
                int row = height - i - 1;
              if (i <= freq)
               {
                  image[row * width + 2*index] = white_pixel;
                  image[row * width + 2*index+1] = white_pixel;
               }
              else
                 {
                   image[row * width + 2*index] = black_pixel;
                   image[row * width + 2*index+1] = black_pixel;
                 }
            }
        }
    }


int main( int argc, char** argv )
{
    int max_freq = 20000; 
    // create input/output streams
    videoSource* input = videoSource::Create(argc, argv, ARG_POSITION(0));
    videoOutput* output = videoOutput::Create(argc, argv, ARG_POSITION(1));
    videoOutput* output2 = videoOutput::Create(argc, argv, ARG_POSITION(1));

    if ( !input )
    return 0;

    uchar4* d_output;
        size_t imageSize = input->GetWidth() * input->GetHeight() * sizeof(uchar4);

    cudaMalloc((void**)&d_output, imageSize);
    int* histogram; 
    cudaMalloc(&histogram, 256*sizeof(int));
    int host_histo[256];

// capture/display loop
    while (true)
    {
        uchar4* image = NULL; // can be uchar3, uchar4, float3, float4
        int status = 0; // see videoSource::Status (OK, TIMEOUT, EOS,ERROR)
        if ( !input->Capture(&image, 1000, &status) ) // 1000ms timeout (default)
        {
            if (status == videoSource::TIMEOUT)
            continue;
            break; // EOS
        }
        rgb2grayKernel<<<16, 1024>>>(image, d_output, input->GetWidth(), input->GetHeight());
        calcHistogramKernel<<<16, 1024>>>(d_output, histogram, input->GetWidth(), input->GetHeight());

        plotHistogramKernel<<<1, 256>>>(d_output,histogram,input->GetWidth(), input->GetHeight(), max_freq);

        // Copy result from device to host
        cudaMemcpy(host_histo, histogram, 256 * sizeof(int), cudaMemcpyDeviceToHost);

        int sum = 0; 
        for (int i = 0; i < 256 ; i++)
        {
            sum += host_histo[i]; 

        }
        printf("%d\n",sum); 

        if ( output != NULL )
        {
            output->Render(image, input->GetWidth(), input->GetHeight());


            // Update status bar
            char str[256];
            sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
            input->GetHeight(), output->GetFrameRate());
            output->SetStatus(str);
            if (!output->IsStreaming()) // check if the user quit
            break;
      }

      if ( output2 != NULL )
      {

          output2->Render(d_output, input->GetWidth(), input->GetHeight());

          // Update status bar
          char str[256];
          sprintf(str, "Camera Viewer (%ux%u) | %0.1f FPS", input->GetWidth(),
          input->GetHeight(), output->GetFrameRate());
          output->SetStatus(str);
          if (!output->IsStreaming()) // check if the user quit
          break;
    }
    }

}


