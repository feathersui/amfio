/*
	AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

import openfl.display.Sprite;
import utest.Runner;
import utest.ui.Report;

class TestMain extends Sprite {
	public function new() {
		super();

		var runner = new Runner();
		runner.addCase(new feathers.amfio.AMFEcmaArrayTest());
		runner.addCase(new feathers.amfio.AMFDictionaryTest());
		runner.addCase(new feathers.amfio.AMF3Test());
		runner.addCase(new feathers.amfio.AMF0Test());
		runner.addCase(new feathers.amfio.sol.SolAMF0Test());
		runner.addCase(new feathers.amfio.sol.SolAMF3Test());

		#if (html5 && playwright)
		// special case: see below for details
		setupHeadlessMode(runner);
		#else
		// a report prints the final results after all tests have run
		Report.create(runner);
		#end

		// don't forget to start the runner
		runner.run();
	}

	#if (html5 && playwright)
	/**
		Developers using continuous integration might want to run the html5
		target in a "headless" browser using playwright. To do that, add
		-Dplaywright to your command line options when building.

		@see https://playwright.dev
	**/
	private function setupHeadlessMode(runner:Runner):Void {
		new utest.ui.text.PrintReport(runner);
		var aggregator = new utest.ui.common.ResultAggregator(runner, true);
		aggregator.onComplete.add(function(result:utest.ui.common.PackageResult):Void {
			Reflect.setField(js.Lib.global, "utestResult", result);
		});
	}
	#end
}
