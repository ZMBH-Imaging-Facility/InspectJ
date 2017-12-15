macro "Main" {
	Initialize();
	allParams = getAllParams();
	allSteps = newArray("Scan Again", "Stop", "Analyze Particles");
	continueFlag = true;
	while (continueFlag) {
		continueFlag = fullScan(allParams, continueFlag);
		if (continueFlag) {
			continueFlag = FijiScan(allParams, continueFlag);
			if (continueFlag) {
				continueFlag = analyzeParticlesDefault(allParams, continueFlag);
				if (continueFlag) {
					nextStep = getNextStep(allSteps);
					if (nextStep == allSteps[2]) {
						continueFlag = analyzeParticlesCustomized(allParams, continueFlag);
					} else if (nextStep == allSteps[1]) {
						continueFlag = false;
					}
				}
			}
		}
	}
	setKeyDown("none");
	print("");
	print("End of the program");
	exit();
}
function getNextStep(allSteps) {
	allSteps_ = Array.slice(allSteps, 0, 2);
	Dialog.create("How to continue?");
	Dialog.addRadioButtonGroup("Next Step", allSteps_, lengthOf(allSteps_), 1, allSteps_[0]);
	Dialog.addCheckbox(allSteps[2], true);
	Dialog.show();
	nextStep = Dialog.getRadioButton;
	checkbox = Dialog.getCheckbox();
	if ((nextStep == allSteps[0]) && checkbox) {
		nextStep = allSteps[2];
	}
	return nextStep;
}
function FijiScan(allParams, continueFlag) {
	if (!getFijiFeaturesScanFlag(allParams)) {
		return continueFlag;
	}
	customizeFijiScansFlag = getCustomizeFijiScansFlag(allParams);
	labels = newArray(
						"Frangi Vesselness",
						"Horizontal Gradient",
						"Vertical Gradient",
						"Gradient Magnitude (WITHOUT smoothing)",
						"Gradient Magnitude (WITH smoothing)",
						"Second-Order Derivative (WITHOUT smoothing)",
						"Second-Order Derivative (WITH smoothing)"
						);
	nLabels = lengthOf(labels);

	default = newArray(false, false, false, false, false, false, false);

	if (customizeFijiScansFlag) {
		Dialog.create("Choice of parameters to scan");
		for (cntr = 0; cntr < nLabels; cntr++) {
			Dialog.addCheckbox(labels[cntr] + "                ", default[cntr]);
		}
		Dialog.show();
		for (cntr = 0; cntr < nLabels; cntr++) {
			default[cntr] = Dialog.getCheckbox();
		}
	}
	continueFlag = setLUTOriginal(allParams, continueFlag);
	setLUT();
	if (default[0] || !customizeFijiScansFlag) {
		continueFlag = applyVesselness(allParams, continueFlag);
	}
	if (default[1] || !customizeFijiScansFlag) {
		continueFlag = applyHorizontalGradient(allParams, continueFlag);
	}
	if (default[2] || !customizeFijiScansFlag) {
		continueFlag = applyVerticalGradient(allParams, continueFlag);
	}
	if (default[3] || !customizeFijiScansFlag) {
		continueFlag = applyGradientMagNoSmooth(allParams, continueFlag);
	}
	if (default[4] || !customizeFijiScansFlag) {
		continueFlag = applyGradientMagWithSmooth(allParams, continueFlag);
	}
	if (default[5] || !customizeFijiScansFlag) {
		continueFlag = applyLaplaceNoSmooth(allParams, continueFlag);
	}
	if (default[6] || !customizeFijiScansFlag) {
		continueFlag = applyLaplaceWithSmooth(allParams, continueFlag);
	}
	return continueFlag;
}
function fullScan(allParams, continueFlag) {
	continueFlag = setLUTOriginal(allParams, continueFlag);
	setLUT();
	continueFlag = equalizeHist(allParams, continueFlag);
	//continueFlag = scanLuts(allParams, continueFlag);
	if (!continueFlag) {
		return continueFlag;
	}
	
	customizeScansFlag = getCustomizeScansFlag(allParams);
	labels = newArray("Effective Brightness/Contrast", "Threshold Levels", "Threshold Types", "Gamma");
	
	nLabels = lengthOf(labels);
	default = newArray(nLabels);
	for (cntr = 0; cntr < nLabels; cntr++) {
		default[cntr] = false;
	}
	if (customizeScansFlag) {
		Dialog.create("Choice of parameters to scan");
		for (cntr = 0; cntr < nLabels; cntr++) {
			Dialog.addCheckbox(labels[cntr] + "                ", default[cntr]);
		}
		Dialog.show();
		for (cntr = 0; cntr < nLabels; cntr++) {
			default[cntr] = Dialog.getCheckbox();
		}
	}

	
	if (default[0] || !customizeScansFlag) {
		continueFlag = scanMinMax(allParams, continueFlag);
		continueFlag = resetMinMax_(allParams, continueFlag);
	}
	continueFlag = sharpen_(allParams, continueFlag);
	continueFlag = findEdges_(allParams, continueFlag);
	if (default[1] || !customizeScansFlag) {
		continueFlag = scanThresholds(allParams, continueFlag);
	}
	if (default[2] || !customizeScansFlag) {
		continueFlag = scanThresholdTypes(allParams, continueFlag);
	}
	if (default[3] || !customizeScansFlag) {
		continueFlag = scanGamma(allParams, continueFlag);
	}
	return continueFlag;
}
function analyzeParticlesDefault(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	setKeyDown("none");
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	nImages_ = nImages;
	setBatchMode(true);
	run("Duplicate...", "title=[" + backupTitle + "]");
	selectWindow_(originalTitle);

	thresholdMethod = "Minimum"; // as opposed to "Default" or ...


	//run("Set Measurements...", "mean shape integrated area_fraction redirect=None decimal=3");
	run("Set Measurements...", "mean shape integrated redirect=None decimal=3");
	if (isBlackBackground(allParams)) {
		setAutoThreshold(thresholdMethod + " dark");
	} else {
		setAutoThreshold(thresholdMethod);
	}
	run("Analyze Particles...", "size=" + getMinSize(allParams) + "-" + getMaxSize(allParams) +
								" circularity=" + getMinCirc(allParams) + "-" + getMaxCirc(allParams) +
								" display clear include add");
	checkForDuplicatesDefault();
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		selectWindow_(backupTitle);
		run("Copy");
		selectWindow_(originalTitle);
		run("Paste");
	}
	close_(backupTitle);
	setBatchMode("exit and display");
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function analyzeParticlesCustomized(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	setKeyDown("none");
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	nImages_ = nImages;
	setBatchMode(true);
	run("Duplicate...", "title=[" + backupTitle + "]");
	selectWindow_(originalTitle);

	thresholdMethod = "Minimum"; // as opposed to "Default" or ...


	//run("Set Measurements...", "mean shape integrated area_fraction redirect=None decimal=3");
	run("Set Measurements...", "mean shape integrated redirect=None decimal=3");
	if (isBlackBackground(allParams)) {
		setAutoThreshold(thresholdMethod + " dark");
	} else {
		setAutoThreshold(thresholdMethod);
	}
	run("Analyze Particles...", "size=" + getMinSize(allParams) + "-" + getMaxSize(allParams) +
								" circularity=" + getMinCirc(allParams) + "-" + getMaxCirc(allParams) +
								" display clear include add");
	checkForDuplicatesCustomized();
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		selectWindow_(backupTitle);
		run("Copy");
		selectWindow_(originalTitle);
		run("Paste");
	}
	close_(backupTitle);
	setBatchMode("exit and display");
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function checkForDuplicatesCustomized() {
	headings = split(String.getResultsHeadings);
	nResults_ = nResults;
	nHeadings = lengthOf(headings);

	initialTolerancePercent = newArray(100, 1, 100, 100, 1, 1, 1);
	

	if (nResults_ == 0) {
		print("No particles were detected with current (threshold/detetcion) settings.");
		return;
	} else if (nResults_ == 1) {
		print("No repeated items were found (only a single paricle was detected).");
		return;
	}

	if (nHeadings != lengthOf(initialTolerancePercent)) {
		 print("Error: Wrongs size of 'Initial Tolerance' (" + (lengthOf(initialTolerancePercent)) + " instead of " + nHeadings + ").");
		 return;
	}


	print("");
	print("");
	print("");
	print("");
	print("");

	print("***");
	print("Second analysis (customized tolerances):");

	descriptorTolerance = newArray(nHeadings);
	for (cntr = 0; cntr < nHeadings; cntr++) {
		descriptorTolerance[cntr] = 0.01 * initialTolerancePercent[cntr];
		//print(headings[cntr] + " = " + (descriptorTolerance[cntr] * 100) + "%");
	}
	
	Dialog.create("Use/Tolerance of Shape Descriptors");
	for (cntr = 0; cntr < nHeadings; cntr++) {
		Dialog.addCheckbox(headings[cntr], true);
		Dialog.addNumber(headings[cntr] + " (percent)", descriptorTolerance[cntr] * 100);
		Dialog.addMessage("");
	}
	Dialog.show();

	for (cntr = 0; cntr < nHeadings; cntr++) {
		if (Dialog.getCheckbox()) {
			descriptorTolerance[cntr] = 0.01 * Dialog.getNumber();
			print(headings[cntr] + " = " + (descriptorTolerance[cntr] * 100) + "%");
		} else {
			dummyVar = Dialog.getNumber();
			descriptorTolerance[cntr] = -1;
			print(headings[cntr] + ": Not used");
		}
	}

	noCloneFlag = true;
	for (row1 = 0; row1 < (nResults_ - 1); row1++) {
		for (row2 = row1 + 1; row2 < nResults_; row2++) {
			bingo = true;
			for (col = 0; col < nHeadings; col++) {
				if (descriptorTolerance[col] != -1) {
					desRow1 = getResult(headings[col], row1);
					desRow2 = getResult(headings[col], row2);
					bingo = bingo && (abs(desRow1 - desRow2) <= descriptorTolerance[col] * minOf(desRow1, desRow2));
				}
			}
			if (bingo) {
				print("Identical items found ('customized tolerances'): " + (row1 + 1) + " and " + (row2 + 1));
				noCloneFlag = false;
			}
		}
	}
	if (noCloneFlag) {
		print("No identical items were found with 'customized tolerances'.");
	}
	print("*****************************");
	
	print("");
	print("");
	print("");
	print("");
	print("");
}
function checkForDuplicatesDefault() {
	headings = split(String.getResultsHeadings);
	nResults_ = nResults;
	nHeadings = lengthOf(headings);

	initialTolerancePercent = newArray(100, 1, 100, 100, 1, 1, 1);
	

	print("");
	print("");
	print("");
	print("");
	print("");

	if (nResults_ == 0) {
		print("No particles were detected with current (threshold/detetcion) settings.");
		return;
	} else if (nResults_ == 1) {
		print("No repeated items were found (only a single paricle was detected).");
		return;
	}

	if (nHeadings != lengthOf(initialTolerancePercent)) {
		 print("Error: Wrongs size of 'Initial Tolerance' (" + (lengthOf(initialTolerancePercent)) + " instead of " + nHeadings + ").");
		 return;
	}

	//warningText = fromCharCode(0x03c0, 0x03c1, 0x03bf, 0x03b5, 0x03b9, 0x03b4, 0x03bf, 0x03c0, 0x03bf, 0x03af, 0x03b7, 0x03c3, 0x03b7);
	print("*****************************");
	warningText = "Looking for possible 'Clones' ...";
	print(warningText);
	wait(2000);
	

	print("***");
	print("First analysis (default tolerances):");

	descriptorTolerance = newArray(nHeadings);
	for (cntr = 0; cntr < nHeadings; cntr++) {
		descriptorTolerance[cntr] = 0.01 * initialTolerancePercent[cntr];
		print(headings[cntr] + " = " + (descriptorTolerance[cntr] * 100) + "%");
	}

	noCloneFlag = true;
	for (row1 = 0; row1 < (nResults_ - 1); row1++) {
		for (row2 = row1 + 1; row2 < nResults_; row2++) {
			bingo = true;
			for (col = 0; col < nHeadings; col++) {
				if (descriptorTolerance[col] != -1) {
					desRow1 = getResult(headings[col], row1);
					desRow2 = getResult(headings[col], row2);
					bingo = bingo && (abs(desRow1 - desRow2) <= descriptorTolerance[col] * minOf(desRow1, desRow2));
				}
			}
			if (bingo) {
				print("Identical items found ('default tolerances'): " + (row1 + 1) + " and " + (row2 + 1));
				noCloneFlag = false;
			}
		}
	}
	if (noCloneFlag) {
		print("No identical items were found with 'default tolerances'.");
	}
	print("***");


	print("");
	print("");
	print("");
	print("");
	print("");
}
function findEdges_(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	nImages_ = nImages;
	setBatchMode(true);
	run("Duplicate...", "title=[" + backupTitle + "]");
	selectWindow_(originalTitle);
	run("Find Edges");
	print("");
	print("Finding edges");
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		selectWindow_(backupTitle);
		run("Copy");
		selectWindow_(originalTitle);
		run("Paste");
	}
	close_(backupTitle);
	setBatchMode("exit and display");
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function equalizeHist(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	nImages_ = nImages;
	setBatchMode(true);
	run("Duplicate...", "title=[" + backupTitle + "]");
	selectWindow_(originalTitle);
	run("Enhance Contrast...", "saturated=0.4 equalize");
	print("");
	print("Equalizing histogram");
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	
	
	
	continueFlag = scanLuts(continueFlag, allParams);
	getLut(reds, greens, blues);
	
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		selectWindow_(backupTitle);
		run("Copy");
		selectWindow_(originalTitle);
		run("Paste");
		setLut(reds, greens, blues);
	}
	close_(backupTitle);
	setBatchMode("exit and display");
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function scanLuts(continueFlag, allParams) {
	//lutValues = newArray("Spectrum", "Cyan", "Red", "Green", "Blue");
	lutValues = getList("LUTs");
	
	nLuts = lengthOf(lutValues);
	print("");
	print("Applying LUTs (nLuts = " + nLuts + "):");
	for (cntr = 0; (cntr < nLuts) && continueFlag; cntr++) {
		continueFlag = applySingleLut(allParams, continueFlag, lutValues[cntr]);
	}
	//print("");
	return continueFlag;
}
function applySingleLut(allParams, continueFlag, lutValue) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	//run("\"" + lutValue + "\"");
	run(lutValue);
	print("Current LUT: " + lutValue);
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function scanGamma(allParams, continueFlag) {
	gammaValues = newArray(0.50, 0.75, 1.00, 1.25, 1.50);
	nGammas = lengthOf(gammaValues);
	print("");
	print("Applying gamma-correction:");
	for (cntr = 0; (cntr < nGammas) && continueFlag; cntr++) {
		continueFlag = scanSingleGamma(allParams, continueFlag, gammaValues[cntr]);
	}
	//print("");
	return continueFlag;
}
function scanSingleGamma(allParams, continueFlag, gamma) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	nImages_ = nImages;
	setBatchMode(true);
	run("Duplicate...", "title=[" + backupTitle + "]");
	selectWindow_(originalTitle);
	run("Macro...", "code=[v = 255 * pow(v/255, " + gamma + ")]");	
	//print("");
	print(""+ fromCharCode(0x03B3) + " = " + gamma + "");
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		selectWindow_(backupTitle);
		run("Copy");
		selectWindow_(originalTitle);
		run("Paste");
	}
	close_(backupTitle);
	setBatchMode("exit and display");
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function sharpen_(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	nImages_ = nImages;
	setBatchMode(true);
	run("Duplicate...", "title=[" + backupTitle + "]");
	selectWindow_(originalTitle);
	run("Sharpen");
	print("");
	print("Sharpenning");
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		selectWindow_(backupTitle);
		run("Copy");
		selectWindow_(originalTitle);
		run("Paste");
	}
	close_(backupTitle);
	setBatchMode("exit and display");
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function selectWindow_(imageTitle) {
	selectWindow(imageTitle);
	while(getTitle() != imageTitle) {
	}
}
function applyLaplaceWithSmooth(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	
	nImages_ = nImages;
	run("FeatureJ Laplacian", "compute smoothing=2.0");
	print("");
	print("Applying Second-Ortder Derivative (WITH smoothing)");
	while (nImages_ == nImages) {
	}
	newTitle = getTitle();
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		close_(newTitle);
	}
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function applyLaplaceNoSmooth(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	
	nImages_ = nImages;
	run("FeatureJ Laplacian", "compute smoothing=1.0");
	print("");
	print("Applying Second-Ortder Derivative (WITHOUT smoothing)");
	while (nImages_ == nImages) {
	}
	newTitle = getTitle();
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		close_(newTitle);
	}
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function applyGradientMagWithSmooth(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	
	nImages_ = nImages;
	run("FeatureJ Edges", "compute smoothing=2.0 lower=[] higher=[]");
	print("");
	print("Applying Gradient Magnitude (WITH smoothing)");
	while (nImages_ == nImages) {
	}
	newTitle = getTitle();
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		close_(newTitle);
	}
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function applyHorizontalGradient(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	
	nImages_ = nImages;
	run("FeatureJ Derivatives", "x-order=1 y-order=0 z-order=0 smoothing=1.0");
	print("");
	print("Applying HORIZONTAL Gradient");
	while (nImages_ == nImages) {
	}
	newTitle = getTitle();
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		close_(newTitle);
	}
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function applyVerticalGradient(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	
	nImages_ = nImages;
	run("FeatureJ Derivatives", "x-order=0 y-order=1 z-order=0 smoothing=1.0");
	print("");
	print("Applying VERTICAL Gradient");
	while (nImages_ == nImages) {
	}
	newTitle = getTitle();
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		close_(newTitle);
	}
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function applyGradientMagNoSmooth(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	
	nImages_ = nImages;
	run("FeatureJ Edges", "compute smoothing=1.0 lower=[] higher=[]");
	print("");
	print("Applying Gradient Magnitude (WITHOUT smoothing)");
	while (nImages_ == nImages) {
	}
	newTitle = getTitle();
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		close_(newTitle);
	}
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function applyVesselness(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);

	setBatchMode("exit and display");
	originalTitle = getTitle();
	backupTitle = originalTitle + "_Backup";
	
	nImages_ = nImages;
	run("Frangi Vesselness (imglib, experimental)", "number=1 minimum=1.000000 maximum=1.000000");
	print("");
	print("Applying Vesselness");
	while (nImages_ == nImages) {
	}
	newTitle = getTitle();
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		close_(newTitle);
	}
	run("Select None");
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function resetMinMax_(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);
	resetMinAndMax();
	getMinAndMax(min, max);
	print("");
	print("minimum pixel value = " + min + ", maximum pixel value = " + max);
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function scanMinMax(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}

	minPixel = getMinPixel(allParams);
	maxPixel = getMaxPixel(allParams);
	nSteps = getNSteps(allParams);
	msDelay = getMSDelay(allParams);
	key = "" + getKey(allParams);
	msDelayLong = getMSDelayLong(allParams);

	step = (maxPixel - minPixel) / nSteps;
	n = 0;
	for (min = minPixel; (min <= (maxPixel - step)) && continueFlag ; min += step) {
		if (2 * floor(n / 2) == n) {
			initialValue = min + step;
			stepValue = step;
		} else {
			initialValue = maxPixel;
			stepValue = - step;
		}
		n++;
		//for (max = min + step; (max <= maxPixel) && continueFlag ; max += step) {
		print("");
		for (max = initialValue; (max <= maxPixel) && (max >= min + step) && continueFlag ; max += stepValue) {
			continueFlag = updateContinueFlag(continueFlag, allParams);
			setMinAndMax(min, max);
			print("minimum pixel value = " + min + ", maximum pixel value = " + max);
			wait(msDelay);
		}
		continueFlag = updateContinueFlag(continueFlag, allParams);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function scanThresholdTypes(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}

	minPixel = getMinPixel(allParams);
	maxPixel = getMaxPixel(allParams);
	nSteps = getNSteps(allParams);
	msDelay = getMSDelay(allParams);
	key = "" + getKey(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);
	methods = getList("threshold.methods");
	nMethods = lengthOf(methods);

	continueFlag = setLUTOriginal(allParams, continueFlag);
	if (!continueFlag) {
		return continueFlag;
	}
	
	print("");
	for (cntr = 0; (cntr < nMethods) && continueFlag; cntr++) {
		if (isBlackBackground(allParams)) {
			setAutoThreshold(methods[cntr] + " dark");
		} else {
			setAutoThreshold(methods[cntr] + "");
		}
		print("Automatic thresholding (method: " + methods[cntr] + ")");
		for (cntr2 = 0; (cntr2 < nDelays) && continueFlag; cntr2++) {
			continueFlag = updateContinueFlag(continueFlag, allParams);
			wait(msDelay);
		}
		continueFlag = updateContinueFlag(continueFlag, allParams);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);

	if (continueFlag) {
		resetThreshold();
		setLUT();
	}
	return continueFlag;
}
function scanThresholds(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}

	minPixel = getMinPixel(allParams);
	maxPixel = getMaxPixel(allParams);
	nSteps = getNSteps(allParams);
	msDelay = getMSDelay(allParams);
	key = "" + getKey(allParams);
	msDelayLong = getMSDelayLong(allParams);

	continueFlag = setLUTOriginal(allParams, continueFlag);
	if (!continueFlag) {
		return continueFlag;
	}

	step = (maxPixel - minPixel) / nSteps;
	n = 0;
	for (min = minPixel; (min <= (maxPixel - step)) && continueFlag ; min += step) {
		if (2 * floor(n / 2) == n) {
			initialValue = min + step;
			stepValue = step;
		} else {
			initialValue = maxPixel;
			stepValue = - step;
		}
		n++;
		//for (max = min + step; (max <= maxPixel) && continueFlag ; max += step) {
		print("");
		for (max = initialValue; (max <= maxPixel) && (max >= min + step) && continueFlag ; max += stepValue) {
			continueFlag = updateContinueFlag(continueFlag, allParams);
			setThreshold(min, max);
			print("minimum threshold = " + min + ", maximum threshold = " + max);
			wait(msDelay);
		}
		continueFlag = updateContinueFlag(continueFlag, allParams);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	if (continueFlag) {
		resetThreshold();
		setLUT();
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function getAllParams() {
	nParams = 20;
	allParams = newArray(nParams);
	Cntr = 0;

	allParams[Cntr++] = "" + 0;			// 0. minPixel
	allParams[Cntr++] = "" + 255;		// 1. maxPixel
	allParams[Cntr++] = "" + 10;		// 2. nSteps
	allParams[Cntr++] = "" + 150;		// 3. msDelay
	allParams[Cntr++] = "" + "space";	// 4. pauseKey
	allParams[Cntr++] = "" + 2000;		// 5. msDelayLong
	allParams[Cntr++] = "" + 1;			// 6. blackBackground
	allParams[Cntr++] = "" + 800;		// 7. keyDelay
	allParams[Cntr++] = "" + "true";	// 8. customizeScansFlag
	allParams[Cntr++] = "" + 10;		// 9. minSize
	allParams[Cntr++] = "" + 100000;	// 10. maxSize
	allParams[Cntr++] = "" + 0.00;		// 11. minCirc
	allParams[Cntr++] = "" + 1.00;		// 12. maxCirc
	allParams[Cntr++] = "" + "shift";	// 13. stopKey
	allParams[Cntr++] = "" + "true";	// 14. FijiFeaturesScanFlag
	allParams[Cntr++] = "" + "true";	// 15. customizeFijiScansFlag

	items = newArray("bright", "dark");
	Dialog.create("Parameters");
	Dialog.addRadioButtonGroup("Background", items, lengthOf(items), 1, items[lengthOf(items) - 1]);
	Dialog.show;
	if (Dialog.getRadioButton == items[0]) {
		allParams[6] = "" + 0;
	} else {
		allParams[6] = "" + 1;
	}
	
	return allParams;
}
function getMinPixel(allParams) {
	return parseInt("" + allParams[0]);
}
function getMaxPixel(allParams) {
	return parseInt("" + allParams[1]);
}
function getNSteps(allParams) {
	return parseInt("" + allParams[2]);
}
function getMSDelay(allParams) {
	return parseInt("" + allParams[3]);
}
function getKey(allParams) {
	return "" + allParams[4];
}
function getMSDelayLong(allParams) {
	return parseInt("" + allParams[5]);
}
function isBlackBackground(allParams) {
	return (parseInt("" + allParams[6]) == 1);
}
function getKeyDelay(allParams) {
	return parseInt("" + allParams[7]);
}
function getCustomizeScansFlag(allParams) {
	return matches(toLowerCase("" + allParams[8]), "true");
}
function getMinSize(allParams) {
	return parseFloat("" + allParams[9]);
}
function getMaxSize(allParams) {
	return parseFloat("" + allParams[10]);
}
function getMinCirc(allParams) {
	return parseFloat("" + allParams[11]);
}
function getMaxCirc(allParams) {
	return parseFloat("" + allParams[12]);
}
function getStopKey(allParams) {
	return "" + allParams[13];
}
function getFijiFeaturesScanFlag(allParams) {
	return matches(toLowerCase("" + allParams[14]), "true");
}
function getCustomizeFijiScansFlag(allParams) {
	return matches(toLowerCase("" + allParams[15]), "true");
}
function Initialize() {
	run("ROI Manager...");
	if (roiManager("count") > 0) {
		roiManager("deselect");
		roiManager("delete");
		while (roiManager("count") > 0) {
		}
	}
	print("\\Clear");
	if (isOpen("Results")) {
		selectWindow("Results");
		wait(100);
		run("Close");
		while (isOpen("Results")) {
		}
	}
	nImages_ = nImages;
	while (nImages_ != 1) {
		if (nImages_ == 0) {
			waitForUser("Please load an image and THEN press OK.");
		} else {
			waitForUser("Please keep only 1 image open and close the rest; THEN press OK.");
		}
		wait(1);
		nImages_ = nImages;
	}
	bitDepth_ = bitDepth;
	if (bitDepth == 24) {
		nImages_ = nImages;
		originalTitle = getTitle();
		run("Split Channels");
		while (nImages != (nImages_ + 2)) {
		}
		while (isOpen(originalTitle)) {
		}

		Dialog.create("Channel(s) to display");
		items = newArray("red", "green", "blue", "all (tripled width)");
		Dialog.addRadioButtonGroup("Channel(s)", items, lengthOf(items), 1, items[lengthOf(items) - 1]);
		Dialog.show;
		selectedChannel = Dialog.getRadioButton;
		if (selectedChannel != items[3]) {
			for (cntr = 0; cntr < 3; cntr++) {
				if (selectedChannel != items[cntr]) {
					close_(originalTitle + " (" + items[cntr] + ")");
				}
			}
			getRawStatistics(nPixels, mean, min, max, std, histogram);
			run("Macro...", "code=[v = 255 * (v - " + min + ") / (" + max + " - " + min + ")]");
		} else {
			nUsedChannels = 0;
			for (cntr = 0; cntr < 3; cntr++) {
				selectWindow_(originalTitle + " (" + items[cntr] + ")");
				getRawStatistics(nPixels, mean, min, max, std, histogram);
				if (max == min) {
					close_(getTitle());
				} else {
					run("Macro...", "code=[v = 255 * (v - " + min + ") / (" + max + " - " + min + ")]");
					nUsedChannels++;
				}
			}
			while (nImages != nUsedChannels) {
			}
			nImages_ = nImages;
			run("Images to Stack", "name=Stack title=[] use");
			while (!isOpen("Stack")) {
			}
			while (nImages != 1) {
			}
			nImages_ = nImages;
			run("Make Montage...", "columns=" + nUsedChannels + " rows=1 scale=1");
			while (nImages != (nImages_ + 1)) {
			}
			while (!isOpen("Montage")) {
			}
			close_("Stack");
		}
	} else {
		getRawStatistics(nPixels, mean, min, max, std, histogram);
		//getMinAndMax(min, max);
		run("Macro...", "code=[v = 255 * (v - " + min + ") / (" + max + " - " + min + ")]");
		run("8-bit");
	}
	run("Remove Overlay");
	removeScale();
	setKeyDown("none");
}
function setLUTOriginal(allParams, continueFlag) {
	if (!continueFlag) {
		return continueFlag;
	}
	key = "" + getKey(allParams);
	msDelay = getMSDelay(allParams);
	msDelayLong = getMSDelayLong(allParams);
	nDelays = - floor (- msDelayLong / msDelay);
	run("Grays");
	print("");
	print("Applying original LUT");
	for (cntr = 0; (cntr < nDelays) && continueFlag; cntr++) {
		continueFlag = updateContinueFlag(continueFlag, allParams);
		wait(msDelay);
	}
	continueFlag = updateContinueFlag(continueFlag, allParams);
	return continueFlag;
}
function updateContinueFlag(continueFlag, allParams) {
	if (!continueFlag) {
		return continueFlag;
	}
	pauseKey = "" + getKey(allParams);
	stopKey = "" + getStopKey(allParams);
	if (isKeyDown(pauseKey)) {
		wait(20);
		while (isKeyDown(pauseKey)) {
			setKeyDown("none");
			wait(20);
		}
		waitForUser;
		wait(1);
	} else if (isKeyDown(stopKey)) {
		wait(20);
		while (isKeyDown(stopKey)) {
			setKeyDown("none");
			wait(20);
		}
		wait(getKeyDelay(allParams));
		continueFlag = getBoolean("Continue?");
		wait(1);
	}
	return continueFlag;
}
function setLUT() {
	lut = "3-3-2 RGB";
	lutPreferred = "Rainbow Smooth";
	allLUTs = getList("LUTs");
	for (cntr = 0; cntr < lengthOf(allLUTs); cntr++) {
		if (allLUTs[cntr] == lutPreferred) {
			lut = lutPreferred;
		}
	}
	run(lut);
}
function close_(imageTitle) {
	selectWindow_(imageTitle);
	run("Close");
	while (isOpen(imageTitle)) {
	}
}
function removeScale() {
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
}
