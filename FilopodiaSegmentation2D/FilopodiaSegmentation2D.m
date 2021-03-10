%%
% FilopodiaSegmentation.
% Copyright (C) 2018 B. Mattes, Y. Dang, S. Scholpp, R. Mikut, J. Stegmaier
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the Liceense at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Please refer to the documentation for more information about the software
% as well as for installation instructions.
%
% If you use this application for your work, please cite the repository and
% the following publication:
%
% Mattes, B., Dang, Y., Greicius, G., Kaufmann, L. T., Prunsche, B., 
% Rosenbauer, J., Stegmaier, J., Mikut, R., Özbek, S., Nienhaus, G. U., 
% Schug, A., Virshup D. M., Scholpp, S., "Wnt/PCP controls spreading of 
% Wnt/β-catenin signals by cytonemes in vertebrates". Elife, 7, e36953, 2018.
%
%%

%% close and clear all previous data
clear settings;
close all;

%% add paths for the live wire and the image reader
if (~isdeployed)
    addpath('../ThirdParty/LiveWire/');
    addpath('../ThirdParty/BioFormats/');
    addpath('../ThirdParty/bresenham/');
    addpath('../ThirdParty/');
end

%% initialize the global settings variable
global settings;
settings = struct();

choice = questdlg('Would you like to open an existing project?', ...
	'Open existing project?', ...
	'Yes','No','No');

%% try to load a project file
if (strcmp(choice, 'Yes') == true)
    [projectFile, projectPath] = uigetfile('*.mat', 'Select an existing project or press cancel to start a new project.');
    load([projectPath projectFile]);
    
    if (~isfield(settings, 'colormapId'))
        settings.colormapId = 1;
    end    
else
    projectPath = uigetdir('Select the folder containing your input data.');
    
    %% preprocess the images with xpiwit
    myfiles = dir(projectPath);
    if (~exist([projectPath filesep 'Results/Data/GFP/'], 'dir'))
        mkdir([projectPath filesep 'Results/Data/GFP/']);
    end
    if (~exist([projectPath filesep 'Results/Data/RFP/'], 'dir'))
        mkdir([projectPath filesep 'Results/Data/RFP/']);
    end
    if (~exist([projectPath filesep 'Results/Data/BF/'], 'dir'))
        mkdir([projectPath filesep 'Results/Data/BF/']);
    end
    if (~exist([projectPath filesep 'Results/Temp'], 'dir'))
        mkdir([projectPath filesep 'Results/Temp']);
    end
    
    settings.projectSettings = inputdlg({'BrightField Channel Index:', 'RFP Channel Index:', 'GFP Channel Index:', 'Pixel Size (microns):', 'Scale Bar Size (microns):'},...
    'Project Settings', [1 50; 1 50; 1 50; 1 50; 1 50], {'1', '2', '3', '0.459', '40'});
    settings.bfChannelIndex = str2double(settings.projectSettings{1});
    settings.rfpChannelIndex = str2double(settings.projectSettings{2});
    settings.gfpChannelIndex = str2double(settings.projectSettings{3});
    settings.pixelToMicrons = str2double(settings.projectSettings{4});
    settings.scaleBarSize = str2double(settings.projectSettings{5});

    for i=1:length(myfiles)
       if (isempty(strfind(myfiles(i).name, '.tif')))
           continue;
       end

       currentImage = imread([projectPath filesep myfiles(i).name], settings.bfChannelIndex);
       imwrite(currentImage, [projectPath filesep 'Results/Data/BF' filesep strrep(myfiles(i).name, '.tif', '_BF.tif')]);
       currentImage = imread([projectPath filesep myfiles(i).name], settings.rfpChannelIndex);
       imwrite(currentImage, [projectPath filesep 'Results/Data/RFP' filesep strrep(myfiles(i).name, '.tif', '_RFP.tif')]);    
       currentImage = imread([projectPath filesep myfiles(i).name], settings.gfpChannelIndex);
       imwrite(currentImage, [projectPath filesep 'Results/Data/GFP' filesep strrep(myfiles(i).name, '.tif', '_GFP.tif')]);    
    end
%     
%     xpiwitCommand = ['XPIWIT.exe --output "' projectPath filesep 'Results/Temp/' '" --input "0, ' projectPath filesep 'Results/Data/RFP/, 2, float" --xml "FilopodiaSegmentationPipeline.xml" --seed "0" --lockfile "off" --subfolder "filterid, filtername" --outputformat "imagename, filtername" --end'];
%     system(xpiwitCommand);

    %% perform instance segmentation using XPIWIT (seeded watershed)
    previousPath = pwd;
    if (ispc)
        cd ../ThirdParty/XPIWIT/Windows/
    elseif (ismac)
        cd ../ThirdParty/XPIWIT/macOS/
    elseif (isunix)
        cd ../ThirdParty/XPIWIT/Linux/
    end

    %% specify the XPIWIT command
    XPIWITCommand1 = ['./XPIWIT.sh ' ...
        '--output "' [projectPath filesep 'Results/Temp/'] '" ' ...
        '--input "0, ' [projectPath filesep 'Results/Data/RFP/'] ', 2, float" ' ...
        '--xml "../FilopodiaSegmentationPipelineReconstructed.xml" ' ...
        '--seed 0 --lockfile off --subfolder "filterid, filtername" --outputformat "imagename, filtername" --end'];

    %% replace slashes by backslashes for windows systems
    if (ispc == true)
        XPIWITCommand1 = strrep(XPIWITCommand1, './XPIWIT.sh', 'XPIWIT.exe');
        XPIWITCommand1 = strrep(XPIWITCommand1, '/', '/');
    end
    system(XPIWITCommand1);
    cd(previousPath);

    
    %% initialize the default variables
    settings.currentImage = 1;
    settings.axesEqual = false;
    settings.meanIntensityWindowSize = 3;
    settings.markerSize = 12;
    settings.positionIndices = 3:5;
    settings.meanIntensityGFPIndex = 6;
    settings.meanIntensityRFPIndex = 7;
    settings.selectionIndex = 8;
    settings.fontSize = 14;
    settings.outputFolder = [projectPath filesep 'Results' filesep];
    settings.projectFileName = [settings.outputFolder 'FilopodiaSegmentationProject.mat'];
    settings.showBrightField = false;
    settings.singleView = true;
    settings.singleViewId = 1;
    settings.colormapId = 1;
    settings.autoUpdate = true;
    settings.scaleBarOffset = [0, 0];
    settings.wntPositiveThreshold = 0.005;
    settings.wntThresholdStep = 0.001;

    %% reset the image file names
    settings.bfImageFolder = [projectPath filesep 'Results/Data/BF/'];
    settings.rfpImageFolder = [projectPath filesep 'Results/Data/RFP/'];
    settings.gfpImageFolder = [projectPath filesep 'Results/Data/GFP/'];
    settings.binaryImageFolder = [projectPath filesep 'Results/Temp/item_0017_BinaryThresholdImageFilter/'];
    settings.objectnessImageFolder = [projectPath filesep 'Results/Temp/item_0004_HessianToObjectnessMeasureImageFilter/'];

    settings.bfImageFileNames = dir(settings.bfImageFolder);
    settings.rfpImageFileNames = dir(settings.rfpImageFolder);
    settings.gfpImageFileNames = dir(settings.gfpImageFolder);
    settings.binaryImageFileNames = dir(settings.binaryImageFolder);
    
    for i=3:length(settings.rfpImageFileNames)
        settings.rfpImage{i-2} = im2double(imread([settings.rfpImageFolder settings.rfpImageFileNames(i).name]));
        settings.gfpImage{i-2} = im2double(imread([settings.gfpImageFolder settings.gfpImageFileNames(i).name]));
        settings.bfImage{i-2} = im2double(imread([settings.bfImageFolder settings.bfImageFileNames(i).name]));
        settings.objectnessImage{i-2} = im2double(imread([settings.objectnessImageFolder strrep(settings.rfpImageFileNames(i).name, '.tif', '_HessianToObjectnessMeasureImageFilter_Out1.tif')]));
        settings.binaryImage{i-2} = im2double(imread([settings.binaryImageFolder strrep(settings.rfpImageFileNames(i).name, '.tif', '_BinaryThresholdImageFilter_Out1.tif')]));
        settings.skeletonImage{i-2} = bwmorph(settings.binaryImage{i-2} > 0, 'skeleton', 'inf');
        settings.endPointImage{i-2} = bwmorph(settings.skeletonImage{i-2}, 'endpoints');
        
        somaImage = adaptivethreshold(settings.rfpImage{i-2}, 200, -std(settings.rfpImage{i-2}(:)));
        somaImage = imfill(imopen(somaImage, strel('disk', 2)), 'holes');

        myregionprops = regionprops(somaImage, 'Area', 'PixelIdxList');
        for j=1:length(myregionprops)
           if (myregionprops(j).Area < 2000)
               somaImage(myregionprops(j).PixelIdxList) = 0;
           end
        end
        
        %figure; imagesc(somaImage);
        settings.somaImage{i-2} = somaImage;  
        settings.perimeterImage{i-2} = bwperim(settings.somaImage{i-2});

        settings.endPoints{i-2} = [];
        settings.perimeterPoints{i-2} = [];

        [settings.endPoints{i-2}(:,4), settings.endPoints{i-2}(:,3)] = ind2sub(size(settings.endPointImage{i-2}), find(settings.endPointImage{i-2} > 0));
        [settings.perimeterPoints{i-2}(:,4), settings.perimeterPoints{i-2}(:,3)] = ind2sub(size(settings.perimeterImage{i-2}), find(settings.perimeterImage{i-2} > 0));
        settings.endPoints{i-2}(:,5) = 0;
        settings.perimeterPoints{i-2}(:,5) = 0;
        settings.endPoints{i-2}(:,settings.selectionIndex) = 0;
        settings.perimeterPoints{i-2}(:,settings.selectionIndex) = 0;
        settings.originalEndPoints{i-2} = settings.endPoints{i-2};
        settings.selectedEndPoints{i-2} = []; %% contains xpos, ypos (rounded!!) and the cell it belongs to

        settings.minGFPIntensity{i-2} = min(settings.gfpImage{i-2}(:));
        settings.minRFPIntensity{i-2} = min(settings.rfpImage{i-2}(:));
        settings.minBFIntensity{i-2} = min(settings.bfImage{i-2}(:));
        settings.maxGFPIntensity{i-2} = max(settings.gfpImage{i-2}(:));
        settings.maxRFPIntensity{i-2} = max(settings.rfpImage{i-2}(:));
        settings.maxBFIntensity{i-2} = max(settings.bfImage{i-2}(:));
        settings.stepGFPIntensity{i-2} = (settings.maxGFPIntensity{i-2} - settings.minGFPIntensity{i-2}) / 30;
        settings.stepRFPIntensity{i-2} = (settings.maxRFPIntensity{i-2} - settings.minRFPIntensity{i-2}) / 30;
        settings.stepBFIntensity{i-2} = (settings.maxBFIntensity{i-2} - settings.minBFIntensity{i-2}) / 30;

        settings.clusterRadius{i-2} = 0;
        settings.currentCell{i-2} = 1;
        settings.currentFilopodia{i-2} = struct();
        settings.manualFilopodia{i-2} = struct();

        disp(['Loading and preprocessing image ' num2str(i-2) ' / ' num2str(length(settings.rfpImageFileNames)-2)]);
    end

    %% set the number of images and the featuer names
    settings.numImages = length(settings.rfpImage);
    settings.featureNames = {'id', 'cellId', 'length (px)', 'RFP Intensity', 'GFP Intensity', 'Wnt Positive'};
end

%% open new figure
settings.mainFigure = figure;
set(gcf,'Color','black');

%% setup the axes for the figure
settings.rfpAxesPosition = [0.0, 0.0, 0.5, 0.5];
settings.rfpAxes = axes('parent', settings.mainFigure, 'units', 'normalized', 'position', settings.rfpAxesPosition);
set(settings.rfpAxes,'Color','black');
settings.rfpAxisRange = [];

%% mouse, keyboard events and window title
set(settings.mainFigure, 'WindowScrollWheelFcn', @ScrollEventHandler);
set(settings.mainFigure, 'KeyReleaseFcn', @KeyReleaseEventHandler);
set(settings.mainFigure, 'ButtonDownFcn', @MouseUp);
set(zoom(settings.mainFigure), 'ActionPostCallback', @ZoomCorrection);
set(pan(settings.mainFigure), 'ActionPostCallback', @PanCorrection);
set(settings.mainFigure, 'CloseRequestFcn', @CloseRequestHandler);

%% initially update the visualization
ResetAxis;
UpdateVisualization;