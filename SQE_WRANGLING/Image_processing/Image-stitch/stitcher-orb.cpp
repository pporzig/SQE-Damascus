#include "opencv2/core/core.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/stitching.hpp"
#include "opencv2/features2d.hpp"

using namespace cv;
using namespace std;

void overlayImage(const cv::Mat &background, const cv::Mat &foreground, cv::Mat &output, cv::Point2i location);

int main(int argc, char* argv[])
{

 Mat first;
 Mat second;
 Mat m_first;
 Mat m_second;
 vector<Mat> images;
// vector<Mat> re_images;
 Mat panorama;
 Mat result;
 unsigned long t;
 t = getTickCount();
 first = imread(argv[1], CV_LOAD_IMAGE_COLOR);
 second = imread(argv[2], CV_LOAD_IMAGE_COLOR);
 //Mat m_first = Mat::zeros( first.size(), first.type() );
 //Mat m_second = Mat::zeros( second.size(), second.type() );
 /*
for( int y = 0; y < first.rows; y++ ) {
    for( int x = 0; x < first.cols; x++ ) {
         for( int c = 0; c < 3; c++ ) {
          m_first.at<Vec3b>(y,x)[c] = saturate_cast<uchar>( 1.2*( first.at<Vec3b>(y,x)[c] ) + 20 );
     }
    }
}

for( int y = 0; y < second.rows; y++ ){
 for( int x = 0; x < second.cols; x++ ) {
         for( int c = 0; c < 3; c++ )  {
      m_second.at<Vec3b>(y,x)[c] =
         saturate_cast<uchar>( 1.2*( second.at<Vec3b>(y,x)[c] ) + 20 );
    }
    }
}
*/
//imwrite("first.png", m_first);
//imwrite("second.png", m_second);
 resize(first, m_first, Size(640, 480));
 resize(second, m_second, Size(640, 480));
 images.push_back(m_first); 
 images.push_back(m_second);


 Stitcher stitcher = Stitcher::createDefault(false);
 //Stitcher::Status status = stitcher.stitch(imgs, pano);
 //stitcher.setWarper(new PlaneWarper());
 stitcher.setWarper(new SphericalWarper());
// stitcher.setWarper(new CylindricalWarper());
 stitcher.setFeaturesFinder(new detail::OrbFeaturesFinder(Size(3,1),1500));
//        stitcher.setRegistrationResol(0.6);
//        stitcher.setSeamEstimationResol(0.1);
//        stitcher.setCompositingResol(0.5);
//stitcher.setPanoConfidenceThresh(1);
        stitcher.setWaveCorrection(true);
        stitcher.setWaveCorrectKind(detail::WAVE_CORRECT_HORIZ);
        stitcher.setFeaturesMatcher(new detail::BestOf2NearestMatcher(false,0.3));
        stitcher.setBundleAdjuster(new detail::BundleAdjusterRay());

        stitcher.setBlender(new detail::MultiBandBlender());
 stitcher.stitch(images, panorama);
 printf("%.2lf sec \n",  (getTickCount() - t) / getTickFrequency() );
 Rect rect(panorama.cols / 2 - 320, panorama.rows / 2 - 240, 640, 480);
 Mat subimage = panorama(rect);
 Mat car = imread("car.png");
 overlayImage(subimage, car, result, cv::Point(320 - (car.cols / 2), 240 - (car.rows / 2 )));
 imshow("panorama", result);
// resize(panorama, result, Size(640, 480));
 imwrite("result.jpg", result);
 waitKey(0); 

 return 0;
}

void overlayImage(const cv::Mat &background, const cv::Mat &foreground, cv::Mat &output, cv::Point2i location)
{
  background.copyTo(output);



   // start at the row indicated by location, or at row 0 if location.y is negative.
  for(int y = std::max(location.y , 0); y < background.rows; ++y)
  {
    int fY = y - location.y; // because of the translation

     // we are done of we have processed all rows of the foreground image.
    if(fY >= foreground.rows)
      break;

     // start at the column indicated by location, 


    // or at column 0 if location.x is negative.
    for(int x = std::max(location.x, 0); x < background.cols; ++x)
    {
      int fX = x - location.x; // because of the translation.

       // we are done with this row if the column is outside of the foreground image.
      if(fX >= foreground.cols)
        break;

       // determine the opacity of the foregrond pixel, using its fourth (alpha) channel.
      double opacity =
        ((double)foreground.data[fY * foreground.step + fX * foreground.channels() + 3])


        / 255.;



       // and now combine the background and foreground pixel, using the opacity, 


      // but only if opacity > 0.
      for(int c = 0; opacity > 0 && c < output.channels(); ++c)
      {
        unsigned char foregroundPx =
          foreground.data[fY * foreground.step + fX * foreground.channels() + c];

        unsigned char backgroundPx =
          background.data[y * background.step + x * background.channels() + c];

        output.data[y*output.step + output.channels()*x + c] =
          backgroundPx * (1.-opacity) + foregroundPx * opacity;

      }
    }
  }
}
