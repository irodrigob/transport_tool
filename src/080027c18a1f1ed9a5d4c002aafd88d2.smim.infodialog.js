sap.ui.define([
    "sap/ui/base/Object"
], function (Object) {
    "use strict";
    return Object.extend("com.irb.trans.controller.infoDialog", {
        _getInfoDialog : function () {
            // create dialog lazily
            if (!this._oDialog) {
                // create dialog via fragment factory
                this._oDialog = sap.ui.xmlfragment("com.irb.trans.fragment.infoDialog", this);
            }
            return this._oDialog;
        },
        open : function (oView) {
            var oDialog = this._getInfoDialog();

            // forward compact/cozy style into Dialog
          //  jQuery.sap.syncStyleClass(oView.getController().getOwnerComponent().getContentDensityClass(), oView, oInfoDialog);

            // connect dialog to view (models, lifecycle)
            oView.addDependent(oDialog);
            // open dialog
            oDialog.open();
        },
        onCloseInfoDialog : function () {
            this._getInfoDialog().close();
        }
    });
});