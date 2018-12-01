
function  stats = objectArd()

cam = webcam();

runLoop = true;
frameCount = 0;
if ismac
    tep=serial('/dev/cu.usbmodem1421','BaudRate', 9600);
elseif ispc
    tep=serial('COM1','BaudRate', 9600);
else
    disp('Platform not supported')
end
fopen(tep);
while runLoop && frameCount<=10000
    data = snapshot(cam); 
    data = fliplr(data);
    frameCount = frameCount + 1;
    h=[];
    h(1) = subplot(4,1,1);
    h(2) = subplot(4,1,[2,3,4]);
    
    diff_im = imsubtract(data(:,:,1), rgb2gray(data));
    diff_im = medfilt2(diff_im, [3 3]);
    diff_im = im2bw(diff_im,0.18);
    diff_im = bwareaopen(diff_im,1500);
    bw = bwlabel(diff_im, 8);
    
    stats = regionprops(bw, 'BoundingBox', 'Centroid');
    
 
    imshow(data,'Parent',h(2));
    if(~ishandle(h(2)))
        runLoop = false;
        fclose(tep);
        close(1);
        clear;
    end
    if(length(stats) >4)
        sampleText=text(15,15, 'ERROR: NUMBER OF RED OBJECTS EXCEEDED');
        set(sampleText, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 20, 'Color', 'RED');
        continue;
    elseif(length(stats)==0)
        sampleText2=text(15,15, 'ERROR: NO RED OBJECTS FOUND');
        set(sampleText2, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 20, 'Color', 'RED');
        continue;
    else
        sampleText2=text(15,15, 'READING');
        set(sampleText2, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 20, 'Color', 'GREEN');
    end
    hold on

    for object = 1:length(stats)
        bb = stats(object).BoundingBox;
        bc = stats(object).Centroid;
        rectangle('Position',bb,'EdgeColor','r','LineWidth',2)
        plot(bc(1),bc(2), '-m+')
        a=text(bc(1)+15,bc(2), strcat('X: ', num2str(round(bc(1))), '    Y: ', num2str(round(bc(2)))));
        set(a, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'yellow');
        drawLines(stats);
    end
    
    hold off
    sendV = drawImageTemp(stats,h(1));
    



    fprintf(tep,'%i', sendV);
    disp('Charater sent to Serial Port is ');
    disp(sendV);

end



fclose(tep);
close(1);
clear;

end

%%drawLine
function drawLines(stats)
    if(length(stats) == 2)
        [l,r] = mini2([1,2], 1, stats);
        plot([stats(l).Centroid(1),stats(r).Centroid(1)],[stats(l).Centroid(2),stats(r).Centroid(2)],'Color','y','LineWidth',2);
    elseif(length(stats) == 3)
        [l1,l2] = mini2([1,2,3], 1, stats);
        if(mini1([l1,l2],2, stats) == l1)
            lt = l1;
            lb = l2;
        else
            lt = l2;
            lb = l1;
        end
        r = maxi1([1,2,3], 1, stats);
        plot([stats(lt).Centroid(1),stats(lb).Centroid(1)],[stats(lt).Centroid(2),stats(lb).Centroid(2)],'Color','y','LineWidth',2);
        plot([stats(lt).Centroid(1),stats(r).Centroid(1)],[stats(lt).Centroid(2),stats(r).Centroid(2)],'Color','y','LineWidth',2);
        plot([stats(lb).Centroid(1),stats(r).Centroid(1)],[stats(lb).Centroid(2),stats(r).Centroid(2)],'Color','y','LineWidth',2);
    elseif(length(stats) == 4)
        [l1,l2] = mini2([1,2,3,4], 1, stats);
        if(mini1([l1,l2],2, stats) == l1)
            lt = l1;
            lb = l2;
        else
            lt = l2;
            lb = l1;
        end
        [r1,r2] = maxi2([1,2,3,4], 1, stats);
        if(mini1([r1,r2],2, stats) == r1)
            rt = r1;
            rb = r2;
        else
            rt = r2;
            rb = r1;
        end
        disp(rt);
        disp(rb);
        plot([stats(lt).Centroid(1),stats(lb).Centroid(1)],[stats(lt).Centroid(2),stats(lb).Centroid(2)],'Color','y','LineWidth',2);
        plot([stats(lt).Centroid(1),stats(rt).Centroid(1)],[stats(lt).Centroid(2),stats(rt).Centroid(2)],'Color','y','LineWidth',2);
        plot([stats(rt).Centroid(1),stats(rb).Centroid(1)],[stats(rt).Centroid(2),stats(rb).Centroid(2)],'Color','y','LineWidth',2);
        plot([stats(lb).Centroid(1),stats(rb).Centroid(1)],[stats(lb).Centroid(2),stats(rb).Centroid(2)],'Color','y','LineWidth',2);
    end
end

function sendV = drawImageTemp(stats,h)
    if ~(length(stats) > 0 && length(stats) <= 4)
        sendV = 0;
        img = imread('ii.jpg');
        fimshow(img,'Parent',h);
    else
        str = getMove(stats);
        disp(str);
        img = imread(str,'jpg');
        imshow(img,'Parent',h);
        if(strcmp(str,'fi')==1)
            sendV = 1;
        elseif(strcmp(str,'fr')==1) 
            sendV = 2;
        elseif(strcmp(str,'ir')==1)
            sendV = 3;
        elseif(strcmp(str,'br')==1)
            sendV = 4;
        elseif(strcmp(str,'bi')==1)
            sendV = 5;
        elseif(strcmp(str,'bl')==1)
            sendV = 6;
        elseif(strcmp(str,'il')==1)
            sendV = 7;
        elseif(strcmp(str,'fl')==1)
            sendV = 8;
        elseif(strcmp(str,'ii')==1)
            sendV = 0;
        end
    end
end


function [ string ] = getMove( stats )
    if(length(stats) == 1 )
        string = 'ii';
    elseif( length(stats) == 2)
        string = strcat('i',get2PointString());
    elseif(length(stats) == 3)
        string = strcat('b',get3PointString());
    else
        string = strcat('f',get4PointString());
    end
%%2POINT    
    function str = get2PointString()
        [l,r] = mini2([1,2], 1, stats);
        if(ch(r,l,200,1))
            if(ch(r,l,100,2))
                str = 'r';
            elseif(ch(l,r,100,2))
                str = 'l';
            else
                str = 'i';
            end
        else
            str = 'i';
        end
    end

%%3POINT
    function str = get3PointString()
        [l1,l2] = mini2([1,2,3], 1, stats);
        if(mini1([l1,l2],2, stats) == l1)
            lt = l1;
            lb = l2;
        else
            lt = l2;
            lb = l1;
        end
        if ~(ch(lb,lt,150,1) || ch(lt,lb,150,1))
            r = maxi1([1,2,3], 1, stats);
            if(ch(r,lt,200,1) && ch(r,lb,200,1) &&ch(lb,lt,100,2))
                if (stats(r).Centroid(2) - (stats(lt).Centroid(2)+((stats(lb).Centroid(2) - (stats(lt).Centroid(2))) / 2))) > 50
                    str = 'r';
                elseif(stats(lt).Centroid(2)+(((stats(lb).Centroid(2) - (stats(lt).Centroid(2))) / 2))-(stats(r).Centroid(2))) > 50
                    str = 'l';
                else
                    str = 'i';
                end
            else
                str = 'i';
            end
        else    
            str = 'i';
        end
    end
    
%%4POINT
    function str = get4PointString()
        [l1,l2] = mini2([1,2,3,4], 1, stats);
        if(mini1([l1,l2],2, stats) == l1)
            lt = l1;
            lb = l2;
        else
            lt = l2;
            lb = l1;
        end
        [r1,r2] = maxi2([1,2,3,4], 1, stats);
        if(mini1([r1,r2],2, stats) == r1)
            rt = r1;
            rb = r2;
        else
            rt = r2;
            rb = r1;
        end

            midl = (stats(lt).Centroid(2)+((stats(lb).Centroid(2) - (stats(lt).Centroid(2))) / 2));
            midr = (stats(rt).Centroid(2)+((stats(rb).Centroid(2) - (stats(rt).Centroid(2))) / 2));
            if ((midr - midl) > 50)
                str = 'r';
            elseif ((midl - midr) > 50)
                str = 'l';
            else
                str = 'i';
            end
    end

%%check diff
    function c = ch(x, y, diff, xy)
        if((stats(x).Centroid(xy) - stats(y).Centroid(xy)) > diff)
            c = true;
        else
            c = false;
        end    
    end

end

%%Max2
    function [ li1,li2 ] = maxi2(index, xy, stats)
        l1 = stats(1).Centroid(xy);
        li1 = 1;
        for len = index
            if(l1<stats(len).Centroid(xy))
                l1 = stats(len).Centroid(xy);
                li1 = len;
            end
        end
        for len = index
            if ~(len == li1)
                l2 = stats(len).Centroid(xy);
                li2 = len;
                break;
            end
        end
        for len = index
            if(l2<stats(len).Centroid(xy) && ~(len == li1))
                l2 = stats(len).Centroid(xy);
                li2 = len;
            end
        end
    end
%%Min2
    function [ li1,li2 ] = mini2(index, xy, stats)
        l1 = stats(1).Centroid(xy);
        li1 = 1;
        for len = index
            if(l1>stats(len).Centroid(xy))
                l1 = stats(len).Centroid(xy);
                li1 = len;
            end
        end
        for len = index
            if ~(len == li1)
                l2 = stats(len).Centroid(xy);
                li2 = len;
                break;
            end
        end
        for len = index
            if(l2>stats(len).Centroid(xy) && ~(len == li1))
                l2 = stats(len).Centroid(xy);
                li2 = len;
            end
        end
    end
%%Max1
    function li = maxi1(index, xy, stats)
        l = stats(1).Centroid(xy);
        li = 1;
        for len = index
            if(l<stats(len).Centroid(xy))
                l = stats(len).Centroid(xy);
                li = len;
            end
        end
    end
%%Min1
    function li = mini1(index, xy, stats)
        l = stats(1).Centroid(xy);
        li = 1;
        for len = index
            if(l>stats(len).Centroid(xy))
                l = stats(len).Centroid(xy);
                li = len;
            end
        end
    end


