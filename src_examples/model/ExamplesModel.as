package model
{
	import views.MetroGalleryExampleView;
	import views.ListExampleView;
	import views.GeneralExampleView;
	import mx.collections.ArrayCollection;

	/**
	 * @author Pavel fljot
	 */
	public class ExamplesModel
	{		
		[Bindable]
		public var examplesList:ArrayCollection = new ArrayCollection(
			[
				{label: "General Example", viewClass: GeneralExampleView}
				,{label: "List Example (snapping)", viewClass: ListExampleView}
				,{label: "Metro Example (paging + snapping)", viewClass: MetroGalleryExampleView}
			]
		);
		
		public var lastViewTitle:String;
	}
}