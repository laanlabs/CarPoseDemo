# Real-time Mobile Car Pose Estimation with CoreML 

#### 🚨NOTE 🚨 Requires [GitLFS](https://git-lfs.github.com/)
If you get build errors this might be the issue.   
Make sure the CarPoseModel.mlmodel is 5.2mb otherwise it has not been downloaded.

![](car.gif)


Small demo of real-time car pose estimation using CoreML trained with synthetic data. 

We used Unity to generate the sythetic car dataset, read more about the project [here](https://medium.com/@laanlabs/real-time-3d-car-pose-estimation-trained-on-synthetic-data-5fa4a2c16634).

### NOTE: 
This model was only trained to handle a specific car model from a fixed viewing distance + angle range. It does work on similar car models, but the pose fit won't match up in 3d space as well. 

Requires [GitLFS](https://git-lfs.github.com/) to download OpenCV framework.

Snapshot of the Unity project:

![](unity.jpg)


## Author

This project was created by Laan Labs. We design and build solutions at the intersection of Computer Vision and Augmented Reality.

[http://labs.laan.com](http://labs.laan.com)

[@laanlabs](https://twitter.com/laanlabs)


## License

CarPoseDemo is released under the MIT License. See [LICENSE](LICENSE) for details.
