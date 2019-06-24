sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageToast",
    "sap/ui/core/routing/History",
    "sap/m/GroupHeaderListItem",
    "sap/ui/model/Filter",
    'sap/m/MessagePopover',
    'sap/m/MessagePopoverItem'
], function (Controller, JSONModel, MessageToast, History, GroupHeaderListItem, Filter, MessagePopover, MessagePopoverItem) {
    "use strict";
    return Controller.extend("com.irb.trans.controller.myOrders", {
        onInit: function () {

            // Leo las RFC del sistema
            dataModel.getSystem(this);

            // Leo las ordenes del usuario de conexion
            dataModel.getUserOrders(this);

            // Si no hay error en la lectura de ordenes navego hacia la vista de ordenes.
            if (this.getOwnerComponent().getModel().getProperty("/userOrdersLoad")){
                this.getOwnerComponent().getRouter().navTo("myOrders");
            }

            // Este modelo me permitira guarda las búsquedas y los filtros de la lista de Ordenes
            this._oUserOrdersFilterState = {
                aFilter: [],
                aSearch: []
            };
            // Este modelo me permitira las búsquedas y filtros de la lista de ordenes
            this._oTaskSelFilterStateFilterState = {
                aFilter: [],
                aSearch: [],
                dChangeFilter: false,
            };

            // Arrary que guardará los números de orden/tarea seleccionados
            this._aOrdersSel = [];

            // Parametros para el transporte. Lo pongo en el modelo global para que sea visible para toda la aplicacion
            var oParamsTransport = new sap.ui.model.json.JSONModel({
                SYSTEM: '',
                DESCRIPTION: ''
            });
            this.getOwnerComponent().setModel(oParamsTransport, "paramsTransport");

            // Oculto las toolbar que pone la semantic page y que no hay manera de quitar, salvo de esta manera
            //un poco guarra.
            sap.ui.getCore().byId("__xmlview1--ordenes-intHeader").setVisible(false);
            sap.ui.getCore().byId("__xmlview1--tareas-intHeader").setVisible(false);


        },
        onNavBack: function (oEvent) {
            var oHistory = History.getInstance();
            var sPreviousHash = oHistory.getPreviousHash();

            if (sPreviousHash !== undefined) {
                window.history.go(-1);
            } else {
                var oRouter = sap.ui.core.UIComponent.getRouterFor(this);
                oRouter.navTo("home", true);
            }
        },
        onAfterRendering: function () {

        },
        getGroupHeader: function (oGroup) {
            return new GroupHeaderListItem({
                title: oGroup.key,
                upperCase: false
            });
        },
        orderSelect: function (oEvent) {

            var oList = oEvent.getSource();
            var oOrders = new sap.ui.model.json.JSONModel({"ORDERS": []});

            // Recupero los contextos de los items seleccionados. El true indica que también los que esten ocultos, por filtro, no se vean.
            var aContextsSel = oList.getSelectedContexts(true);

            for (var x = 0; x < aContextsSel.length; x++) {

                // El path viene con / que lo quito para tener el índice real
                var indice = aContextsSel[x].getPath().substring(1);

                // Recupero el model
                var oModel = aContextsSel[x].getModel().getData()[indice];

                // Se lo añado a un modelo local bajo la etiqueta ORDERS. Esta etiqueta permite crear el arbol
                oOrders.getData().ORDERS.push(oModel);
            }

            // Si no hay ordenes seleccionadas oculto el boton de transportar(por si estuviera marcado) y limpio el array
            // donde se guardan las ordenes seleccionadas
            if (oOrders.getData().ORDERS.length == 0) {
                this.getView().byId("btnTransport").setVisible(false);
                this._aOrdersSel = [];
            }

            // Actualización del modelo de ordenes seleccionadas
            this.updateModelOrdersSel(oOrders);


        },
        // Función que actualiza el modelo de ordenes seleccionadas.
        updateModelOrdersSel:function(pModel){
            // Se lo paso al modelo del componente que es el que usa el arbol de ordenes seleccionadas
            this.getOwnerComponent().setModel(pModel, "OrdersSelected");

            // Refresco el listado
            this.getView().byId("ordersSelected").getModel().refresh(true);


            // Expando hasta el primer nivel, el de las tareas para que se vean.
            this.getView().byId("ordersSelected").expandToLevel(1);

            // Cada nueva seleccion hay que aplicar el filtro. Si no se ha cambiado aplico el filtro por defecto
            if (!this._oTaskSelFilterStateFilterState.dChangeFilter) {
                this._defaultFilterTask();
            }
            else {
                this._applyFilterSearchTask();
            }
        },
        onSearchOrder: function (oEvent) {

            var aFilters = [];
            // Se recupera el valor introducido en el campo de búsuqeda
            var sQuery = oEvent.getSource().getValue();

            // Obtengo el binding(donde están los datos) para añadirle el filtro.
            var oBinding = this.getView().byId("userOrders").getBinding("items");

            // Si hay contenido creo el fitro. Lo hago de manera distinta si solo hubiera un filtro, pero es que sino, no funciona.
            if (sQuery && sQuery.length > 0) {
                // Primer filtro por descripcion y segundo orden por orden
                aFilters = [new Filter("DESCRIPTION", sap.ui.model.FilterOperator.Contains, sQuery),
                    new Filter("ORDER", sap.ui.model.FilterOperator.Contains, sQuery)];

                // Paso el filtro a los datos. El false final es para indicar que los filtros se comporten como OR
                this._oUserOrdersFilterState.aSearch = [new Filter(aFilters, false)];
            }
            else {
                // Si no hay datos a filtro paso el filtro el blanco para que muestre todo
                this._oUserOrdersFilterState.aSearch = [];
            }

            // Aplico los filtros
            this._applyFilterSearchOrders();


        },
        // Funcion que abre la ventana de settings de las ordenes del usuario
        onOpenSettingUserOrders: function () {
            if (!this._oSettingsOrder) {
                this._oSettingsOrder = sap.ui.xmlfragment("com.irb.trans.fragment.settingsUserOrders", this);
                this.getView().addDependent(this._oSettingsOrder);
                // forward compact/cozy style into Dialog
                this._oSettingsOrder.addStyleClass(this.getOwnerComponent().getContentDensityClass());
            }
            this._oSettingsOrder.open();
        },
        // Funcion que abre la ventana de settings de las tareas seleccionadas
        onOpenSettingTask: function () {
            if (!this._oSettingsTask) {
                this._oSettingsTask = sap.ui.xmlfragment("com.irb.trans.fragment.settingsTask", this);
                this.getView().addDependent(this._oSettingsTask);
                // forward compact/cozy style into Dialog
                this._oSettingsTask.addStyleClass(this.getOwnerComponent().getContentDensityClass());
            }
            this._oSettingsTask.open();
        },

        // Funcion que aplica los filtros seleccionado en la ventana Settings.
        onConfirmSettingsUserOrders: function (oEvent) {

            var aFilterItems = oEvent.getParameters().filterItems;
            var aFilters = [];

            aFilterItems.forEach(function (oItem) {
                switch (oItem.getKey()) {
                    case "orderTypeK" :
                        aFilters.push(new Filter("TYPE", sap.ui.model.FilterOperator.EQ, DC_ORDER_TYPE_CUSTOMIZING));
                        break;
                    case "orderTypeW" :
                        aFilters.push(new Filter("TYPE", sap.ui.model.FilterOperator.EQ, DC_ORDER_TYPE_WORKBENCH));
                        break;
                    case "orderTypeT" :
                        aFilters.push(new Filter("TYPE", sap.ui.model.FilterOperator.EQ, DC_ORDER_TYPE_TRANSPORT));
                        break;
                    default :
                        break;
                }

            });

            this._oUserOrdersFilterState.aFilter = aFilters; // Paso el filtro al modelo interno
            this._applyFilterSearchOrders(); // Refresco dicho filtro


        },
        onRowSelectionChange: function (oEvent) {
            // Array con las ordenes seleccionadas
            this._aOrdersSel = [];

            ///ORDERS/1/TASKS/0 --> Como viene el path

            if (oEvent.oSource.getSelectedIndices().length > 0) {

                this.getView().byId("btnTransport").setVisible(true); // Se muestra el botón de transportar

                // Recupero los datos del tree control.
                var oData = this.getOwnerComponent().getModel("OrdersSelected").getData();

                // Tabla con los datos de las ordenes seleccionadas
                var oTable = this.getView().byId("ordersSelected");


                for (var x = 0; x < oEvent.oSource.getSelectedIndices().length; x++) {

                    // Obtengo el path seleccionado
                    var oContext = oTable.getContextByIndex(oEvent.oSource.getSelectedIndices()[x]);

                    // Separo el path en partes para saber cada indice a buscar.
                    var aIndices = oContext.getPath().split("/");

                    // Se puede seleccionar por orden o la tarea. El acceso al modelo dependerá de que se ha seleccionado
                    // En ambos casos el primer nivel siempre será la orden por lo que busco la posicion seleccionado
                    var indiceOrders = aIndices[2];

                    if (oContext.getPath().indexOf('TASKS') != -1) {
                        var indiceTasks = aIndices[4];
                        var order = oData.ORDERS[indiceOrders].TASKS[indiceTasks].ORDER;
                    }
                    else {
                        var order = oData.ORDERS[indiceOrders].ORDER;
                    }

                    // Añado la orden/tarea
                    this._aOrdersSel.push(order);

                }
            }
            else {
                this.getView().byId("btnTransport").setVisible(false);
            }

        },

        // Funcion que se llama cuando se confirma el fragmento: settingsTask.fragment.xml
        onConfirmSettingsTask: function (oEvent) {

            // código para las opciones de visualizacion de tareas
            if (this.getOwnerComponent().getModel("OrdersSelected") != undefined) {
                if (this.getOwnerComponent().getModel("OrdersSelected").getData().ORDERS.length > 0) {

                    var aFilters = [];

                    this._oTaskSelFilterStateFilterState.dChangeFilter = true; // Marco que se ha cambiado el filtro

                    switch (sap.ui.getCore().byId("showTask").getSelectedKey()) {
                        case "showTaskModifiable":
                            aFilters.push(new Filter("STATUS", sap.ui.model.FilterOperator.EQ, DC_TASK_STATUS_MODIF));
                            break;
                        case "showTaskAll":
                            // Sin filtro para que lea todas
                            break;
                    }
                    this._oTaskSelFilterStateFilterState.aFilter = aFilters;
                    this._applyFilterSearchTask();
                }
            }
        },

        // Realizacion del transporte de copias.
        onTransport: function () {
            this.resetMsgTransport(); // Reset del área de mensajes del resultado del transporte
            this.onOpenParamsTransport(); // Parametros del transporte

        },
        // Muestra el popopver
        onOpenLog: function (oEvent) {
            this.oPopOver.openBy(oEvent.getSource());
        },
        // Abre la ventana para introducir/seleccionar los parámetros para el transporte.
        onOpenParamsTransport: function () {
            if (!this._oParamsTransport) {
                this._oParamsTransport = sap.ui.xmlfragment("com.irb.trans.fragment.paramsTransportDialog", this);
                this.getView().addDependent(this._oParamsTransport);
                // forward compact/cozy style into Dialog
                this._oParamsTransport.addStyleClass(this.getOwnerComponent().getContentDensityClass());
            }
            this._oParamsTransport.open();
        },
        // Confirmación de los parametros de transporte
        onConfirmParamsTransport: function () {

            // Se cierra la ventana de dialogo
            this._oParamsTransport.close();

            sap.ui.core.BusyIndicator.show(0);

            var aOrders = []
            for (var x = 0; x < this._aOrdersSel.length; x++) {
                aOrders.push({"ORDER": this._aOrdersSel[x]});
            }
            var oEntry = {
                "DATA": {
                    "PARAMS": this.getOwnerComponent().getModel("paramsTransport").getData(),
                    "ORDERS": JSON.parse(JSON.stringify(aOrders))
                }
            };

            // Guardo las ordenes en el modelo global y se llama al método que realiza el transporte
            this.getOwnerComponent().setModel(oEntry, "ordersTransport");
            dataModel.setTransport(this);

        },
        onCancelParamsTransport: function () {
            this._oParamsTransport.close();
        },
        completeTransport: function (pReturn, pOrder) {
            // Muestro el boton de log
            this.getView().byId("btnLogTransport").setVisible(true);

            // Recupero el resultado de la llamada
            //var oReturn = this.getOwnerComponent().getModel("resultTransport");

            // Creo el popover donde se mostrará el resultado
            this.oPopOver = util.createPopOverReturn(pReturn, this);

            sap.ui.core.BusyIndicator.hide();

            // Saco el texto tanto si ha ido bien como mal.
            var text = "";
            if (!util.isEmpty(pOrder))
                text = this.getOwnerComponent().getModel("i18n").getResourceBundle().getText("myOrders.Detail.Task.msgTransportDone", [pOrder]);
            else
                text = this.getOwnerComponent().getModel("i18n").getResourceBundle().getText("myOrders.Detail.Task.msgTransportFail");

            MessageToast.show(text);
        },
        // Reset de la zona donde se muestran los mensajes del proceso de transporte
        resetMsgTransport: function () {

            // Botón de transporte desaparece
            this.getView().byId("btnLogTransport").setVisible(false);

            // Si el modelo de la vista donde se guarda el numero de mensajes existe lo actualizo para dejarlo en blanco
            if (!util.isEmpty(this.getView().getModel().getData().numMsgReturn)) {
                var viewModel = this.getView().getModel(viewModel);
                viewModel.getData().numMsgReturn = "";
                this.getView().setModel(viewModel);
            }


        },
        // Refresco de las ordenes
        onRefreshOrders:function(){

            // Reseto de las ordenes seleccionadas
            this.resetOrdersSel();

            // Reseteo las ordenes leidas
            this.resetOrders();

            // Leo las ordenes del usuario de conexion
            dataModel.getUserOrders(this);



        },
        // Reset de las ordenes leídas
        resetOrders: function () {
            var dataModel = this.getOwnerComponent().getModel("UserOrders");
            if(dataModel){
                dataModel.setData(null);
                dataModel.updateBindings(true);
            }
        },
        // Reset de las ordenes seleccionadas
        resetOrdersSel:function(){
            // Primero he de resetear los valores de las ordenes  seleccionadas

            var dataModel = this.getOwnerComponent().getModel("OrdersSelected");
            if(dataModel){
                dataModel.setData(null);
                dataModel.updateBindings(true);
            }


            // Oculto boton de transporte y limpio la matriz de ordenes seleccionadas
            this.getView().byId("btnTransport").setVisible(false);
            this._aOrdersSel = [];
        },

        /*  METODOS PRIVADOS */
        _applyFilterSearchOrders: function () {

            // Concateno tanto el filtro de búsqueda como los filtros predefinidos en un solo
            var aFilters = this._oUserOrdersFilterState.aSearch.concat(this._oUserOrdersFilterState.aFilter);

            // Aplico el filtro al los datos de la lista de ordenes del usuario
            this.getView().byId("userOrders").getBinding("items").filter(aFilters, "Application");


        },
        // Funcion que poner el filtro por defecto de las tareas
        _defaultFilterTask: function () {
            var aFilters = [];
            aFilters.push(new Filter("STATUS", sap.ui.model.FilterOperator.EQ, DC_TASK_STATUS_MODIF));
            this._oTaskSelFilterStateFilterState.aFilter = aFilters;
            this._applyFilterSearchTask();
        },
        _applyFilterSearchTask: function () {
            // Concateno tanto el filtro de búsqueda como los filtros predefinidos en un solo
            var aFilters = this._oTaskSelFilterStateFilterState.aSearch.concat(this._oTaskSelFilterStateFilterState.aFilter);

            // Aplico el filtro al los datos de la lista de ordenes del usuario
            this.getView().byId("ordersSelected").getBinding("rows").filter(aFilters, "Application");
        }


    });
});

