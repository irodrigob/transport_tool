var dataModel = {
    getUserInfo:function(pController){

        RESTUtil.readSAP(
            pController.getOwnerComponent().getMetadata().getManifestEntry("sap.ui5").models.appData.user,
            '{"DATA":{"USERNAME": ""}}', // opciones para SAP
            pController,
            function successHandler(data) {

                var oUser = new sap.ui.model.json.JSONModel(data.DATA);

                pController.getOwnerComponent().setModel(oUser, "User");

                pController.getOwnerComponent().getModel().setProperty("/userLoad", true);

                console.log("getUserInfo - success");


            },
            function errorHandler(data, status) {

                console.log("getUserInfo - failed");

                pController.getOwnerComponent().getModel().setProperty("/userLoad", false);

                // recupero el texto que se mostrara cuando se pueda recuperar del error producido
                var resourceBundle = pController.getOwnerComponent().getModel("i18n").getResourceBundle();
                var text = resourceBundle.getText("dataModel.getUserInfo");

                RESTUtil.manageErrorResponse(pController, "V", data, text);

            }
        );

    },
    getUserOrders: function (pController) {
        var lang = pController.getOwnerComponent().getModel().getProperty("/Spras");


        RESTUtil.readSAP(
            pController.getOwnerComponent().getMetadata().getManifestEntry("sap.ui5").models.appData.userOrders,
            '{"DATA":{"USERNAME": ""}}', // opciones para SAP
            pController,
            function successHandler(data) {

                var oUserOrders = new sap.ui.model.json.JSONModel(data.DATA);

                pController.getOwnerComponent().setModel(oUserOrders, "UserOrders");

                pController.getOwnerComponent().getModel().setProperty("/userOrdersLoad", true);

                console.log("getUserOrder - success");


            },
            function errorHandler(data, status) {

                console.log("getUserOrder - failed");

                pController.getOwnerComponent().getModel().setProperty("/userOrdersLoad", false);

                // recupero el texto que se mostrara cuando se pueda recuperar del error producido
                var resourceBundle = pController.getOwnerComponent().getModel("i18n").getResourceBundle();
                var text = resourceBundle.getText("dataModel.getUserOrders");

                RESTUtil.manageErrorResponse(pController, "V", data, text);

            }
        );

    },
    getSystem: function (pController) {
        var lang = pController.getOwnerComponent().getModel().getProperty("/Spras");


        RESTUtil.readSAP(
            pController.getOwnerComponent().getMetadata().getManifestEntry("sap.ui5").models.appData.rfc,
            "", // opciones para SAP
            pController,
            function successHandler(data) {

                var oSystem = new sap.ui.model.json.JSONModel(data.DATA);

                pController.getOwnerComponent().setModel(oSystem, "SYSTEM");

                pController.getOwnerComponent().getModel().setProperty("/RFCLoad", true);

                console.log("getSystem - success");


            },
            function errorHandler(data, status) {

                console.log("getSystem - failed");

                pController.getOwnerComponent().getModel().setProperty("/SystemLoad", false);

                // recupero el texto que se mostrara cuando se pueda recuperar del error producido
                var resourceBundle = pController.getOwnerComponent().getModel("i18n").getResourceBundle();
                var text = resourceBundle.getText("dataModel.getSystem");

                RESTUtil.manageErrorResponse(pController, "V", data, text);

            }
        );

    },
    setTransport: function (pController) {

        // Si los datos se leen de fichero el RESTUTIL no hará nada, por eso, redirigo al método que se ejecuta cuando
        // el transporte se hace correctamente
        if (pController.getOwnerComponent().getMetadata().getConfig().custApp.typeReadModel == DC_TYPE_READ_MODEL_FILE) {
            pController.completeTransport();
        }
        else {
            var oModel = pController.getOwnerComponent().getModel("ordersTransport");
            RESTUtil.updateSAP(
                pController.getOwnerComponent().getMetadata().getManifestEntry("sap.ui5").models.appData.transport,
                oModel, // opciones para SAP
                pController,
                function successHandler(data) {

                    console.log("setTransport - success");

                    var oReturn = util.convertReturn2PopOver(data.DATA.RETURN);

                    pController.completeTransport(oReturn, data.DATA.ORDER);


                },
                function errorHandler(data, status) {

                    console.log("setTransport - failed");

                    // recupero el texto que se mostrara cuando se pueda recuperar del error producido
                    var resourceBundle = pController.getOwnerComponent().getModel("i18n").getResourceBundle();
                    var text = resourceBundle.getText("dataModel.setTransport");

                    RESTUtil.manageErrorResponse(pController, "V", data, text);
                }
            );
        }

    }
}
