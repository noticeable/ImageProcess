function []=feat_extractor()
 vl_setupnn;
 %model path:
 model_path='D:/dataset/models/imagenet-vgg-verydeep-19.mat';
 data_mean_path='D:/dataset/HLeaf/data_mean.mat';
 %abnormal:
 image_root_path='D:/dataset/HLeaf/abnormal/';
 feat_root_path='D:/dataset/HLeaf/cascade_feat/abnormal/';
 image_count=170;
 
 %normal:
%  image_root_path='D:/dataset/HLeaf/normal/';
%  feat_root_path='D:/dataset/HLeaf/cascade_feat/normal/';
%
%  image_count=6428;
   mkdir(feat_root_path);
 %level=42;
 level_list=[6,11,20,29,38,42];
 net=load(model_path);
 load(data_mean_path);
 for i=1:image_count
   i
   img_filename=[image_root_path,'image_',sprintf('%04d',i),'.jpg'];
   feat_filename=[feat_root_path,'image_',sprintf('%04d',i),'.mat'];
   if (~exist(feat_filename,'file'))
       im=imread(img_filename);
       im=imresize(im,[net.normalization.imageSize(1,1),net.normalization.imageSize(1,2)]);
       im=double(im)-data_mean;
       im=single(im); 
       res=vl_simplenn(net,im);
       tmp_feat={};
       for p=1:size(level_list,2)
         tmp_feat{p}=gather(res(level_list(1,p)).x(:)');
       end
       save(feat_filename,'tmp_feat');
   end
 end
 

end