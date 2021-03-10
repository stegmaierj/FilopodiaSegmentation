%% Using the semi-automatic filopodia segmentation
%% - Start the FilopodiaSegmentation.exe
%% - Load the stack you want to perform the segmentation on
%% - Use the mouse wheel to navigate within the stack (xy-slices are displayed)
%% - To segment a filopodium, Shift+Click the end pointing towards the cell membrane it is attached to
%% - Use the mouse wheel to navigate to the slice containing the tip of the filopodium and finalize the segmentation with another Shift+Click on the tip
%% - The software automatically traces the filopodium based on the two click points in xy, yz and xz maximum projections that are defined by the click locations
%% - Segmented filopodia have a unique id and are plotted over the maximum projection. A second figure displays the properties of the last segmented filopodium
%% - Each filopodium is assigned to the current cell id. Use +/- to change the current cell id, e.g., if you want to start the segmentations for a new cell press '+' once.
%% - Use the 'W' button to toggle the Wnt-Positive flag of the filopodia (red: Wnt negative, green: Wnt positive)
%% - Use the 'R' button to switch the direction of the current filipodia (in cases where segmentation started at the tip of the filopodia)
%%
%% - The remaining keyboard shortcuts are as defined below
%% +/-: Increase/Decrease the current cell id (filopodia belonging to different cells are saved to different tables)
%% A: Assign current cell id to the currently selected filopodia
%% D: Delete currently selected filopodia
%% H: Displays help dialog
%% I: Zoom to the currently selected filopodia
%% M: Enables Maximum-Projection Mode, i.e., during the tracing of filopodia, the maximum projection of startZ to endZ is visualized.
%% N: Create new project (be sure to save your current project before!)
%% O: Zoom out to the default view
%% R: Revert the direction of the currently selected filopodia
%% S: Save the current project overwriting the current project file
%% W: Toggles the Wnt-Positive flag of the currently selected filopodia
%% ALT+Click: Selects the filopodia that is closest to the cursor
%% CTRL+S: Save the current project with a new project file name
%% CTRL+Wheel: Zoom in/out using a Google maps-like behavior
%% SHIFT+Click: Start/end a new filopodia trace (SHIFT+Click once at both ends of the filopodia)
%% Space: Enables the pan mode to move the main segmentation window
%% Wheel: Scroll through the slices of the stack