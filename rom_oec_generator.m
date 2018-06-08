%%This Matlab script can be used for generating .coe files for 
%constructing ROMs using Xilinx's IP-Core wizard

filename='dungeon';
row=240;
column=320;

a=imread(strcat(filename,'.png'));
b= round(a./256);
f = zeros(row,column); 
g = cell(row,1);

for i=1:row
    for j=1:column
        f(i,j)= b(i,j,1) || b(i,j,2)|| b(i,j,3);
    end
end
imshow(f);


for i=1:row
    for j=1:column
        g(i)=strcat(g(i),num2str(f(i,j)));
    end 
end



fileID = fopen(strcat(filename,'.coe'),'w');

formatSpec='%s\r\n';
fprintf(fileID,formatSpec,"memory_initialization_radix = 2;");
fprintf(fileID,formatSpec,"memory_initialization_vector =");

formatSpec='%s,\r\n'; 
for i = 1:(row-1)
    fprintf(fileID,formatSpec,g{i,:});
end

formatSpec='%s;\r\n';
fprintf(fileID,formatSpec,g{row,:});

fclose(fileID);
