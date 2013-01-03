function[minTeta,minPhi] = analizeRadius(mat , name)
%gets a mat of raduses acurding to angels
 boneMaxDiameter = 40


AngleJump = 1 / (size(mat,1) / 180.0)
 %normal from 0 to 1
 pic = (mat -  min(mat(:))) ./ (max(mat(:)) - min(mat(:)));
 figure('Name', strcat(name, ' presision=', num2str(AngleJump)));
imshow(pic);

%get and print data 
minRadius = min(mat(:))
[minTeta,minPhi] = find(mat == minRadius);
if size(minTeta,2) > 1
    ThereIsMoreThenOneRadius = 1
    minTeta = minTeta(1);
    minPhi = minPhi(1);
end
minTeta = minTeta * AngleJump;
minPhi = minPhi* AngleJump;
radiusDeviation = boneMaxDiameter * abs ( 1 - cos(AngleJump*pi/180) +sin(AngleJump*pi/180) )

% get area that could have a better radius
couldHaveBetter = mat < (minRadius + radiusDeviation);
figure('Name', 'could Have Better radius');
imshow(~couldHaveBetter);

couldHaveBetterSize = sum(couldHaveBetter(:));
%each pixel represnt a squere
couldHaveBetterAreaSize = couldHaveBetterSize * AngleJump * AngleJump

%x = Teta , y = Phi
[x , y] = find(couldHaveBetter);
tetaRange = [(min(x)*AngleJump - AngleJump) (max(x)*AngleJump + AngleJump)]
PhiRange = [(min(y)*AngleJump - AngleJump) (max(y)*AngleJump + AngleJump)]
couldHaveBetterBoxSize = (tetaRange(2) - tetaRange(1)) * (PhiRange(2) - PhiRange(1))


end

