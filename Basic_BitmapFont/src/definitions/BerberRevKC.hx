package definitions;

import away3d.textfield.utils.FontContainer;
import away3d.textfield.utils.FontSize;
import definitions.berberRevKC.BerberRevKC_260;

class BerberRevKC extends FontContainer
{
	{
		size260 = new BerberRevKC_260();
	}
	public static var size260:FontSize;
	
	public function BerberRevKC()
	{
		addSize(size260);
	}
}