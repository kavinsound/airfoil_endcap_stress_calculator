cd(fileparts(mfilename('fullpath'))) %set directory for writing
clear;
clc;

% INPUTS
name = "FW-Primary-Large";
len = 29.72; %Airfoil Surface Length (in)
Torque = 10; %Bolt torque (in*lb)
FoS = 3; %Factor of Safety
diameter = 0.25; %Bolt Diameter (in)
K = 0.25; %Nut Friction Factor
infill = 0.15; %endcap infill percent
endcap_area = 13.937; %Surface area of endcap
bolt_type = "#1/4-20";

% END OF INPUTS

%MATERIAL DATASHEET



materials = readtable('Mat_Props.csv');


numMaterials = height(materials);

materialsArray = struct();

for i = 1:numMaterials
    materialsArray(i).name = materials.Materials{i};
    materialsArray(i).shear = materials.Shear(i);
    materialsArray(i).density = materials.Density(i);
end

thickness = zeros(numMaterials,3);
mass = zeros(numMaterials,3);
materialNames = strings(numMaterials,1);






%main function to solve for area and mass
function [th1, th2, th3, mass1, mass2, mass3] = solver(l, t, fos, d, k, in, a, adh_sh, dens) % (Airfoil length, Bolt torque, FoS, Bolt Diameter, Nut Friction, Infill %, Endcap Area, Max Adhesive Shear, Material Density)
    clamp_f = t ./ (d * k);  %Force of bolt equation
    allowed_sh = adh_sh ./ fos;    %Allowed shear with FoS
    load = 2 * clamp_f;     %Load on endcap
    a_req = load ./ allowed_sh;   %Required surface area of adhesive
    
    th1 = a_req ./ l;     %[OUTPUT] Thickness of endcap required for surface area (in)
    mm = 0.0394;
    th2 = th1 + mm;
    th3 = th2 + mm;
    wall_a = l * 1.2 * mm;
    in_a = a - wall_a;
    mass1 = wall_a * th1 * dens + in_a * th1 * dens * in;      %[OUTPUT] Mass of endcap (g)
    mass2 = wall_a * th2 * dens + in_a * th2 * dens * in;  
    mass3 = wall_a * th3 * dens + in_a * th3 * dens * in;  
end

% LOOP OVER MATERIALS
for i = 1:numMaterials
    [thickness(i, 1), thickness(i, 2), thickness(i, 3), mass(i, 1), mass(i, 2), mass(i, 3)] = solver(len, Torque,FoS,diameter,K,infill,endcap_area,materialsArray(i).shear,materialsArray(i).density);

    materialNames(i) = materialsArray(i).name;
end
r_l = length(thickness(1));
%Display Table
results = table(name, bolt_type, thickness(1:r_l, 1), mass(1:r_l, 1), thickness(1:r_l, 2), mass(1:r_l, 2), thickness(1:r_l, 3), mass(1:r_l, 3),'VariableNames', ['Wing', 'Bolt', 'Th_in','Mass', 'Th_in+1mm', 'Mass+1mm', "Th_in+2mm", 'Mass+2mm']);
disp(results)

writetable(results, name + "-results.csv");