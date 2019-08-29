function []=brightfield_trachea()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%BRIGHTFIELD_TRACHEA
%This script is used to quantify tracheal branch density
%in Drosophila posterior midgut bright field images.
%%%USE
%Brightfield images are focus-stacked in Adobe Photoshop and exported into
%individual folders in tiff file format. Call the program and select a folder
%containing the individual folders and a second output folder for the results
%to be saved. The variable disp can be used to toggle the display of
%intermediate processing steps.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%Display intermediate steps. Boolean
disp=1;

path=uigetdir([],'Select folder of files to be analysed');
save=uigetdir([],'Select Save folder');

%%%If input is not empty/cancelled
if all(path~=0)
    cd(path)
    main=dir;
	%%%Cycle through all images in folder
    for x=1:length(main)
        cd(path)
        if main(x).isdir
            cd(main(x).name)
            % % % Get file names
            file_list=dir;
            % % % For all files in the directory
            for i=1:length(file_list)
                % % % Find image
                if strcmp(file_list(i).name,'Untitled1.tif')
                    % % % Load Adobe PS pre-processed image
                    im=imread('Untitled1.tif');
					% % % Grayscale
                    im=rgb2gray(im);
					% % % CLAHE
                    im2=adapthisteq(im);
					% % % Invert
                    im3=255-im2;
					% % % Background subtraction
                    im4=imtophat(im3, strel('disk', 12));
					% % % Re-adjust contrast
                    im4=imadjust(im4);
					% % % Otsu thresholding
                    bw=im4>(graythresh(im4)*255);
					% % % Morphological opening to denoise
                    bw2=bwareaopen(bw,40);
                    
                    % % % Save image
                    cd(save)
                    imwrite(bw2,[num2str(x),'.tif'])
                    
                    if disp
                        figure, imshow(im), title('Original')
                        figure, imshow(im3), title('Hist+negative')
                        figure, imshow(im4), title('Background')
                        figure, imshow(bw), title('BW')
                        figure, imshow(bw2), title('Small removed')
                    end
					
                end
            end
        end
    end
end

end


function [density]=bright_skeleton()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%BRIGHT_SKELETON
%This function processes and skeletonises output images of the 
%brightfield_trachea function.
%%%USE
%Call the function and select a folder where brightfield_trachea files were
%saved.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%clear all
path=uigetdir([],'Select folder of files to be analysed');
%%%If input is not empty/cancelled
if all(path~=0)
    cd(path)
    % % % Get file names
    file_list=dir;
    % % % Initialise rolling counter
    a=0;
    % % % For all files in the directory
    for i=1:length(file_list)
        filename_length=length(file_list(i).name);
        % % % Run only if mask of the gut file is present
        if filename_length>9  && strcmp(file_list(i).name(filename_length-7:end),'mask.tif')
		% % % Load file and manual mask
            mask=imread(file_list(i).name);
            bw=imread([file_list(i).name(1:filename_length-9),'tif']);
            
			% % % Apply mask to trachea
            bw=mask&bw;
            
            % % % Morphological processing
            bw=bwmorph(bw,'diag');
            bw=bwmorph(bw,'close');
            bw=bwmorph(bw,'spur');
            skel=bwmorph(bw,'thin',Inf);
            skel=bwmorph(skel,'clean');
			% % % Uncomment to show skeleton overlayed the thresholded image
%             figure, imshow(skel), title('Skeletonized image')
%             figure;
%             rgb(:,:,1)=skel*255;
%             rgb(:,:,2)=skel*0;
%             rgb(:,:,3)=skel*0;
%             imshow(rgb)
%             hold on
%             kep=imshow(bw);
%             set(kep,'AlphaData',0.5)
%             title('Overlay of skeleton and bw')
            
            % % % Spur
            limit=20;
            skel2=spur(skel,limit);
            % % % Advance counter
            a=a+1;
			% % % Count branchpoints
            branch{a}=bwmorph(skel2,'branchpoints');
            number{a}=sum(sum(branch{a}));
			% % % Calculate branchpoint density
            density{a}=number{a}/sum(mask(:));
            
			% % % Uncomment to display the difference between the original skeleton
			%and the spurred version.
%             difference=skel-skel2;
%             figure;
%             rgb(:,:,1)=difference*255;
%             rgb(:,:,2)=skel*0;
%             rgb(:,:,3)=skel*0;
%             imshow(rgb)
%             hold on
%             kep2=imshow(bw);
%             set(kep2,'AlphaData',0.5)
%             title('Overlay of Spurred and bw')
%             
%             clear rgb
            
            % % % Save results
            imwrite(skel,[file_list(i).name(1:filename_length-10),'_skeleton.tif'])
            imwrite(skel2,[file_list(i).name(1:filename_length-10),'_spurred_skeleton.tif'])
        end
    end
end



function [skelD]=spur(skel, limit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%SPUR
%This function removes spur pixels from skeletonised images.
%%%USE
%Call the function with skel variable as a 2D matrix of the skeletonised image.
%Limit is the length above which the branch is considered true.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
B = bwmorph(skel, 'branchpoints');
E = bwmorph(skel, 'endpoints');
[y,x] = find(E);
B_loc = find(B);
Dmask = false(size(skel));
a=waitbar(0,'0% Percent');
l=numel(x);
for k = 1:l
    D = bwdistgeodesic(skel,x(k),y(k));
    distanceToBranchPt = min(D(B_loc));
    if distanceToBranchPt<limit
    Dmask(D < distanceToBranchPt) =true;
    end
    waitbar(k/l,a,[num2str(100*k/l),'% Percent'])
end
skelD = skel - Dmask;

% % % Uncomment to display identified branchpoints.
% figure
% imshow(skelD);
% hold all;
% [y,x] = find(B); plot(x,y,'ro')
delete(a)
end
