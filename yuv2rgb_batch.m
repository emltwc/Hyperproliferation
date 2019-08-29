path=uigetdir;
cd(path)

files=dir;

length=size(files,1)-2;

for i=1:length
   if  size(files(i).name,2)>3
    im=imread(files(i).name);
    img=yuv2rgb(im);
    imwrite(img,files(i).name);
   end
end