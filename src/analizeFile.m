function analizeFile( fileName )
%gets a row of raduses acurding to angels
fileD= fopen(fileName);
tRow = textscan(fileD,'%f');

 mat = tRow{1};
 mat = reshape(mat,sqrt(size(mat,1)),sqrt(size(mat,1)));
 cuttingLastRow =1
 mat = mat([1:1:1800],[1:1:1800]);
 [minTeta01,minPhi01] = analizeRadius(mat , fileName );
 
 mat1 = mat([1:10:1800],[1:10:1800]);
 [minTeta1,minPhi1] = analizeRadius(mat1 , '0.1 to 1' );
 tetaDef = minTeta01 - minTeta1
 phiDef = minPhi01 - minPhi1
 
 minRadius1 = min(mat1(:))
 betterThen1 = minRadius1 >= mat; 
 [x , y] = find(betterThen1);
 AngleJump = 1 / (size(mat,1) / 180.0);
tetaRange = [(min(x)*AngleJump - AngleJump) (max(x)*AngleJump + AngleJump)];
PhiRange = [(min(y)*AngleJump - AngleJump) (max(y)*AngleJump + AngleJump)];
tetaRangelength1 = - (min(x)*AngleJump - AngleJump) + (max(x)*AngleJump + AngleJump)
PhiRangelength1 = -(min(y)*AngleJump - AngleJump) + (max(y)*AngleJump + AngleJump)
figure('Name', '0.1 is better then 1');
imshow(~betterThen1);

mat05 = mat([1:5:1800],[1:5:1800]);
 [minTeta05,minPhi05] = analizeRadius(mat05 , '0.1 to 0.5' );
 tetaDef = minTeta01 - minTeta05
 phiDef = minPhi01 - minPhi05
 
 minRadius05 = min(mat05(:))
 betterThen05 = minRadius05 >= mat; 
 [x , y] = find(betterThen05);
 AngleJump = 1 / (size(mat,1) / 180.0);
tetaRange = [(min(x)*AngleJump - AngleJump) (max(x)*AngleJump + AngleJump)];
PhiRange = [(min(y)*AngleJump - AngleJump) (max(y)*AngleJump + AngleJump)];
tetaRangelength05 = - (min(x)*AngleJump - AngleJump) + (max(x)*AngleJump + AngleJump)
PhiRangelength05 = -(min(y)*AngleJump - AngleJump) + (max(y)*AngleJump + AngleJump)
figure('Name', '0.1 is better then 0.5');
imshow(~betterThen05);
end

