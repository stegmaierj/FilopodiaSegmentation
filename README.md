# FilopodiaSegmentation
MATLAB Tools for Semi-Automatic Segmentation of Filopodia in 2D and 3D Microscopy Images [1].

## Getting Started
To get started using the FilopodiaSegmentation tool, youll need a recent version of MATLAB. Moreover, the processing requires [XPIWIT](https://bitbucket.org/jstegmaier/xpiwit/downloads/) for preprocessing [2]. Download the latest version for the operating system youre using and copy the files contained in the `%XPIWITRoot%/Bin/` to `%FilopodiaSegmentationRoot%/ThirdParty/XPIWIT/{Windows/macOS/Linux}%`. XPIWIT will be called automatically by the FilopodiaSegmentation tool and you only need to make sure that the XPIWIT executable and the dynamic libraries have execution permissions by your operating system. You can test this by simply double-clicking the XPIWIT executable and checking if the following output is displayed in the terminal window: 

```
Starting XPIWIT
Processing piped arguments
```

After that works, youre all set to start segmenting filopodia. Simply open the respective start script `FilopodiaSegmentation2D.m` or `FilopodiaSegmentation3D.m` in MATLAB and hit the run button to execute the script. The following sections explain how to use the 2D and 3D version, respectively. For the 2D version, we also provide precompiled executable for Windows that can be downloaded [here](https://github.com/stegmaierj/FilopodiaSegmentation/blob/main/Bin/FilopodiaSegmentation2D.zip).

## FilopodiaSegmentation2D
The script first asks for a folder to process. This folder should contain 3-channel `*.tif` files and all images contained in the folder will be preprocessed and can be further analyzed in the GUI. Make sure to adjust the settings dialog according to the specs of your images. Most importantly, the script needs to know which channel corresponds to Brightfield/RFP/GFP, respectively. Moreover, to get correct length measurements it is important to set the physical pixel size in microns appropriately.

<center><img src="Data/Screenshots/ProjectSettings2D.png" alt="Parameter Settings" width="250"></center>

### Workflow
After the preprocessing finished, you should see a window like the following, which is the main workbench of the GUI:

![File Open Dialog](Data/Screenshots/GUIOverview2D.png)

The common procedure for analysis is as follows:
1. Check if the cell body you want to segment is correctly detected (outline matches the black/cyan points). If not, re-draw the outline using the “Q” button.
2. Press Button “R” to draw a region of interest containing the current cell body you want to analyze as well as all filopodia belonging to that cell, such  that the program knows to which cell center it should trace the filopodia tips and which filopodia tips to use.
3. Select/Deselect filopodia such that all correct filopodia of the current cell are labeled. This can be done using the `S` and `D` keys. After pressing one of the keys, you can use the freehand drawing tool to highlight the respective filopodia.
4. If auto-update is not turned on, hit the `E` button to extract the currently selected filopodia.
5. Optionally, you can use the `M` button to manually draw a filopodium.
6. If you’re satisfied with the current cell, you can move either to the next cell using the `arrow up` key (cell counter on top left increases) and starting over again at point 1 by circling the region of interest for the next cell. If you want to later correct an earlier cell, simply use the `arrow down` button until you see that the filopodia of the cell of interest are highlighted.
7. If all cells within the image were segmented and annotated properly, you can switch to the next image and perform steps 1-6 again using the `arrow right`. Going back to one of the previous images can be done by `left arrow`.
8. Don’t forget to save the project once in a while, such that you don’t loose any data using the `G` button.

See keyboard commands in the next section for more details and additional functionality.


### Keyboard Commands

- 1,2,3,4: Switch view between GFP/RFP/Hessian/Skeleton Images
- A: Add a new filopodia tip if a detection is missing
- D: De-select a single filopodia tip or filopodia tips in a region
- E: Extract all currently selected filopodia and trace the tips to the soma
- G: Save the project and filopodia statistics to disk
- I: Allows to select a filopodium tip and shows the properties
- N: Manually draw a filopodium using line segments (double-click to finish)
- M: Manually draw a filopodium in free hand mode
- P: Open propeties dialog to adjust the scale bar size, location and units
- Q: Manually re-draw the soma boundaries if the automatic detection is erroneous
- R: Select the region of interest, i.e., a cell and all its filopodia that should be counted
- S: Select a single filopodia tip or filopodia tips in a region
- O: Open different image or another project (folder containing tiff files to start a new project or *.mat to open an existing project)
- U: Toggles auto update. If enabled, each change causes an update of the filopodia (e.g. after roi selection/tip selection/tip deselection)
- W: Show the Wnt expression of the selected filopodia in a scatter plot
- C/V: Show previous/next colormap
- X: Toggles aspect ratio of the image (original aspect ratio / stretched to the window size)
- +/-: Increase/decrease the cluster radius to merge close filopodia tips (Perform this as the first step, even before ROI selection).
- ./,: Increase/decrease the wnt threshold. Tips with a GFP value larger than this theshold will be counted as wnt positive / cytonemes.
- Arrow Up/Arrow Down: Increase/decrease the cell counter.
- Left Arrow: Decrease image id (to navigate between different images of a project)
- Right Arrow: Increase image id (to navigate between different images of a project)
- Wheel: Scroll through the slices of the stack
- CTRL+Wheel: Increase/decrease zoom

Hint: In case key presses show no effect, left click once on the image and try hitting the button again. This only happens if the window looses the focus.

## FilopodiaSegmentation3D
Initially, the script will ask for an input image. This should be an image in the *.lif or the *.ims format. The script uses Bioformats for reading, i.e., it could be that other formats will also work but may require slight modifications of the code. 

The code for adapted readers is contained in the file `ReadLifImage.m` and most importantly the following lines in `FilopodiaSegmentation3D.m` need to make sure that both channels are properly loaded. A 3D image for the Wnt channel and one for the membrane signal.

```MATLAB
    [settings.wntImage, settings.rawImage, ~] = ReadLifImage(settings.rawImageFileName, settings.selectedSeries, settings.wntChannel, settings.memChannel);
```

If the loading worked properly, all contained 3D images will be displayed in a preview window and you can then select which of the series you want to work on. 

![File Open Dialog](Data/Screenshots/ProjectSettings3D.png "")

Make sure to adjust the settings dialog according to the specs of your images. Most importantly, the script needs to know which channel corresponds to Wnt/membranes, respectively. Moreover, to get correct length measurements it is important to set the physical voxel size appropriately. The edge enhancement flag can disable the XPIWIT-based preprocessing and will then directly operate on the raw intensities for tracing the filopodia. The folder `%FilopodiaSegmentationRoot%/Data/3D/` contains a test image in the `*.ims` format that can be used to get familiar with the software.

### Workflow
Once the image was loaded successfully, you can start manually tracing filopodia in the image. Use the mouse wheel to scroll through the slices. Once you found a filopodium to trace, use `Shift + Left Mouse Button` to start the tracing. Then move the cursor to the end of the filopodium and hit `Shift + Left Mouse Button` again to trace the filipodium. You can revert the direction of the filopodium, such that the colored circle is located at its tip. Just continue adding filopodia in the same way until all interesting structures are labeled. The Wnt active/positive flag can be toggled for each filopodium with the `W` key and the grayscale and the composite visualization on the bottom right give an impression of the expression in the Wnt channel. Moreover, to select a different filopodium, just hit the `alt` key and use the crosshair to indicate which filopodium to select. The object closest to the curser will then be highlighted in magenta. If filopodia should be recorded separately for different cells, you can increase/decrease the cell counter with the `+/-` keys. 

![File Open Dialog](Data/Screenshots/GUIOverview.png "")

Finally, the project and the current results can be saved using the `s` key. Select the desired output filename and it will create a `*.mat` file containing the project information in case you want to continue later (select `Load Project` when starting the `FilopodiaSegmentation3D.m`). Moreover, the measurements for each individual filopodium is saved in an Excel/CSV format. For an overview of all keyboard commands, see the listing in the next section.

![File Open Dialog](Data/Screenshots/ResultsTable.png "")

### Keyboard Commands

- +/-: Increase/Decrease the current cell id (filopodia belonging to different cells are saved to different tables)

- A: Assign current cell id to the currently selected filopodia            
- D: Delete currently selected filopodia
- E: Export data to an Excel spreadsheet
- H: Displays this help dialog
- I: Zoom to the currently selected filopodia
- M: Maximum projection mode. If you scroll while drawing a filopodium, maximum projections of the slices will be generated to assist hitting the right point in a separate plane.
- N: Create new project (be sure to save your current project before!)
- O: Zoom out to the default view
- R: Revert the direction of the currently selected filopodia
- S: Save the current project and a csv table with the current results
- W: Toggles the Wnt-Positive flag of the currently selected filopodia
- ALT+Click: Selects the filopodia that is closest to the cursor
- CTRL+S: Save the current project with a new project file name
- CTRL+Wheel: Zoom in/out using a Google maps-like behavior
- SHIFT+Click: Start/end a new filopodia trace - (SHIFT+Click once at both ends of the filopodia)
- Space: Enables the pan mode to move the main segmentation window
- Wheel: Scroll through the slices of the stack

## References

1. Mattes, B., Dang, Y., Greicius, G., Kaufmann, L. T., Prunsche, B., Rosenbauer, J., Stegmaier, J., Mikut, R., Özbek, S., Nienhaus, G. U., Schug, A., Virshup D. M., Scholpp, S.(2018). Wnt/PCP controls spreading of Wnt/β-catenin signals by cytonemes in vertebrates. Elife, 7, e36953.

2. Bartschat, A., Hübner, E., Reischl, M., Mikut, R., & Stegmaier, J. (2016). XPIWIT—an XML Pipeline Wrapper for the Insight Toolkit. Bioinformatics, 32(2), 315-317.