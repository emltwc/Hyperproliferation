function cafe()

% vid = videoinput('winvideo', 1, 'YUY2_2304x1536');
% preview(vid)


timing=inputdlg('Enter the time in seconds between consecutive images','Timing',1,{'60'});
timing=str2num(timing{1});
path=uigetdir([],'Select folder for images to be saved');

if ~isempty(path)
    cd(path)
    
    vid = videoinput('winvideo', 1, 'YUY2_2304x1536');
    
    tic
    while 1==1
        
        if toc>=timing
            tic
            time=clock;
            picture=getsnapshot(vid);
            t{1}=time(1);
            t{2}=time(2);
            if time(3)<10
                t{3}=['0',time(3)];
            else
                t{3}=time(3);
            end
            if time(3)<10
                t{3}=['0',num2str(time(3))];
            else
                t{3}=time(3);
            end
            if time(4)<10
                t{4}=['0',num2str(time(4))];
            else
                t{4}=time(4);
            end
            if time(5)<10
                t{5}=['0',num2str(time(5))];
            else
                t{5}=time(5);
            end
            if time(6)<10
                t{6}=['0',num2str(round(time(6)))];
            else
                t{6}=round(time(6));
            end
            
            date=[num2str(t{1}),'-',num2str(t{2}),'-',num2str(t{3}),'-',num2str(t{4}),'-',num2str(t{5}),'-',num2str(t{6}),'.jpg'];
            
            imwrite(picture,date,'jpg')
        end
    end
end