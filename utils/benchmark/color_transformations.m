% MATLAB script for checking the implemented color transformations in 
% the camera class from linear RGB to CIEXYZ and CIELAB color values.

clear all;
format short

%% Define linear RGB color values

% Linear RGB color
r = randi([0, 255]);
g = randi([0, 255]);
b = randi([0, 255]);

% White refernce point (d65)
ref_x = 0.9504;
ref_y = 1.0000;
ref_z = 1.0888;

disp('Linear rgb')
disp([r, g, b])


%% CIEXYZ

disp('CIEXYZ')

% Transfrom from linear RGB to XYZ
xyz = rgb2xyz([r/255, g/255, b/255], 'ColorSpace', 'linear-rgb'); % Uses a default (d65) whitepoint
disp(xyz)

% RGB to XYZ
% From: https://en.wikipedia.org/wiki/SRGB
R = r/255;
G = g/255;
B = b/255;

b11 = 0.4124;
b12 = 0.3576;
b13 = 0.1805;
b21 = 0.2126;
b22 = 0.7152;
b23 = 0.0722;
b31 = 0.0193;
b32 = 0.1192;
b33 = 0.9505;    

x = b11*R + b12*G + b13*B; 
y = b21*R + b22*G + b23*B;
z = b31*R + b32*G + b33*B;
disp([x, y, z])

% Error
disp([round(abs(xyz(1) - x), 4), round(abs(xyz(2) - y), 4), round(abs(xyz(3) - z), 4)])


%% CIELAB

disp('CIELAB')

% Transform from linear RGB to LAB
lab = rgb2lab([r/255, g/255, b/255], 'ColorSpace', 'linear-rgb', 'WhitePoint', [ref_x, ref_y, ref_z]);
disp(lab)
lab = xyz2lab([x, y, z], 'WhitePoint', [ref_x, ref_y, ref_z]);
disp(lab)

% XYZ to RGB
% From: https://nl.wikipedia.org/wiki/CIELAB

delta = 6/29;

if x/ref_x > delta^3
    fx = (x/ref_x)^(1/3);
else
    fx = (x/ref_x)/(3*delta^2) + delta;
end

if y/ref_y > delta^3
    fy = (y/ref_y)^(1/3);
else
    fy = (y/ref_y)/(3*delta^2) + delta;
end

if z/ref_z > delta^3
    fz = (z/ref_z)^(1/3);
else
    fz = (z/ref_z)/(3*delta^2) + delta;
end

L_star = 116*(fy) - 16;
a_star = 500*fx - 500*fy;
b_star = 200*fy - 200*fz;

disp([L_star, a_star, b_star])

% Error
disp([round(abs(lab(1) - L_star), 4), round(abs(lab(2) - a_star), 4), round(abs(lab(3) - b_star), 4)])
disp([fx, fy, fz])


%% End

disp('End')

