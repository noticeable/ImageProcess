
function [ret] = GenerateTRARawInfo(destFile)
%����ĳһ��Ƶ�ļ�������spatial�µ�trajectory�����ӽṹ��
  spatial_size=8;
  spatial_cof=0.70;
  vl_setup;
  obj=VideoReader(destFile);  %�õ�����һ��object
  vidFrames=read(obj);     %�õ���������֡������
  numFrames=obj.numberOfFrames;  %����֡������
  ret=[];
  
  disp('*****Initialize Video...');
   for i=1:numFrames                                 
     mov(i).cdata=vidFrames(:,:,:,i);                                
     mov(i).cdata=rgb2gray(mov(i).cdata);                                
     mov(i).cdata=single(mov(i).cdata);  
   end
   
   [height0,width0]=size(mov(1).cdata);              %��ʼ�߶ȺͿ���
   for i=1:spatial_size
     disp(['*******Handling spatial:',num2str(i)]);
     height=round(height0*spatial_cof^(i-1));width=round(width0*spatial_cof^(i-1));
    
     for j=1:numFrames
         mov(j).cdata=imresize(mov(j).cdata,[height,width]);
     end
     
     ofInfo=GetOpticalFlowInfo(mov);
     ret=[ret;GetTrajectory(mov,ofInfo)];
   end

end

%����ԭ��Ƶ�͹�����Ϣ��ȡtrajectory
function [traMat]=GetTrajectory(mov,ofInfo)
  traMat=[];
  gridSize=5;
  [height,width]=size(mov(1).cdata);
  
  pt_x=round(linspace(1,height,round(height/gridSize)+1));            %���ɳ�ʼ�����㴹ֱ����
  pt_y=round(linspace(1,width,round(width/gridSize)+1));              %���ɳ�ʼ������ˮƽ����
  L=15;
  
  cood=zeros(size(pt_x,2),size(pt_y,2),L,2);                %��¼ÿ�����15֡����:�кţ��кţ�֡����x��y
  
  %��ʼ����װ���һ֡����
  for i=1:size(pt_x,2)
      for j=1:size(pt_y,2)
         cood(i,j,1,1)=pt_x(i);cood(i,j,1,2)=pt_y(j);
      end
  end
  
  p=1;
  
  for frameCount=1:size(ofInfo,2)-1
    u=ofInfo(frameCount).u;v=ofInfo(frameCount).v;
    p=p+1;
    
    for i=1:size(pt_x,2)
        for j=1:size(pt_y,2)
          cood(i,j,p,1)=cood(i,j,p-1,1)+v(i,j);       %��ֱ������λ��
          cood(i,j,p,2)=cood(i,j,p-1,2)+u(i,j);       %ˮƽ������λ��
%           %��ֹԽ��
%           cood(i,j,frameCount+1,1)=max(1,cood(i,j,frameCount+1,1));cood(i,j,frameCount+1,1)=min(height,cood(i,j,frameCount+1,1));
%           cood(i,j,frameCount+1,2)=max(1,cood(i,j,frameCount+1,2));cood(i,j,frameCount+1,2)=min(width,cood(i,j,frameCount+1,2));        
        end
    end
    if (mod(p,L)==0)
       %ȡ��15֡��,��������Ҫ���������vector T
   
       for i2=1:size(pt_x,2)
           for j2=1:size(pt_y,2)
               vec=zeros(1,(p-1)*2);
               sum=double(0);
               for k2=1:p-1
                   vec(1,2*k2-1)=cood(i2,j2,k2+1,1)-cood(i2,j2,k2,1);
                   vec(1,2*k2)=cood(i2,j2,k2+1,2)-cood(i2,j2,k2,2);
                   sum=sum+sqrt(vec(1,2*k2-1)^2+vec(1,2*k2)^2);
               end
               
               if (sum==0)
                   sum=1;
               end
               vec=vec./sum;
               traMat=[traMat;vec];
           end
       end
       
       %���¶�cood���г�ʼ������
          for i2=1:size(pt_x,2)
              for j2=1:size(pt_y,2)
                 cood(i2,j2,1,1)=pt_x(i2);cood(i2,j2,1,2)=pt_y(j2);
              end
          end
       p=1;
    end
  end
  

end

%��ȡ������Ϣ��
function [ofInfo2]=GetOpticalFlowInfo(mov)

    %���ڹ���������ϵͳ����
    hof=vision.OpticalFlow('ReferenceFrameDelay',1,'ReferenceFrameSource','Input port');
    hof.OutputValue='Horizontal and vertical components in complex form';
    ofInfo={};
    for i=1:size(mov,2)-1
        %����һ��Ҫȷ����single��
        frame=mov(i).cdata;
        frame_ref=mov(i+1).cdata;
        ofInfo{i} = step (hof,frame,frame_ref); %�ù���������Ƶ�е�ÿһ֡ͼ����д���,����Ҫ�ľ������of ��complex����ʽ������ÿ�����ת���ٶ�
    end
     
    ofInfo{size(mov,2)}=ofInfo{size(mov,2)-1};
    for i=1:size(mov,2)
       tmp=ofInfo{i};
       u=real(tmp); v=imag(tmp);                                        %uΪˮƽ��vΪ��ֱ
       ofInfo2(i).u=medfilt2(u,[3,3]);ofInfo2(i).v=medfilt2(v,[3,3]);   %��optical flow������ֵ�˲�
    end
end
