(window["webpackJsonp"] = window["webpackJsonp"] || []).push([["main"],{

/***/ "./src/$$_lazy_route_resource lazy recursive":
/*!**********************************************************!*\
  !*** ./src/$$_lazy_route_resource lazy namespace object ***!
  \**********************************************************/
/*! no static exports found */
/***/ (function(module, exports) {

function webpackEmptyAsyncContext(req) {
	// Here Promise.resolve().then() is used instead of new Promise() to prevent
	// uncaught exception popping up in devtools
	return Promise.resolve().then(function() {
		var e = new Error("Cannot find module '" + req + "'");
		e.code = 'MODULE_NOT_FOUND';
		throw e;
	});
}
webpackEmptyAsyncContext.keys = function() { return []; };
webpackEmptyAsyncContext.resolve = webpackEmptyAsyncContext;
module.exports = webpackEmptyAsyncContext;
webpackEmptyAsyncContext.id = "./src/$$_lazy_route_resource lazy recursive";

/***/ }),

/***/ "./src/app/app.component.css":
/*!***********************************!*\
  !*** ./src/app/app.component.css ***!
  \***********************************/
/*! no static exports found */
/***/ (function(module, exports) {

module.exports = ""

/***/ }),

/***/ "./src/app/app.component.html":
/*!************************************!*\
  !*** ./src/app/app.component.html ***!
  \************************************/
/*! no static exports found */
/***/ (function(module, exports) {

module.exports = "<!--The content below is only a placeholder and can be replaced.-->\n<app-job-searcher></app-job-searcher>\n"

/***/ }),

/***/ "./src/app/app.component.ts":
/*!**********************************!*\
  !*** ./src/app/app.component.ts ***!
  \**********************************/
/*! exports provided: AppComponent */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "AppComponent", function() { return AppComponent; });
/* harmony import */ var _angular_core__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @angular/core */ "./node_modules/@angular/core/fesm5/core.js");
var __decorate = (undefined && undefined.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (undefined && undefined.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};

var AppComponent = /** @class */ (function () {
    function AppComponent() {
        this.title = 'ExternalPluginExample-RemoteServer';
        zosmfExternalTools.cleanupBeforeDestroy = function (obj) {
            // doing cleanup work
            console.log("Cleanup work done!");
            zosmfExternalTools.cleanupBeforeDestroyComplete(obj);
        };
    }
    AppComponent = __decorate([
        Object(_angular_core__WEBPACK_IMPORTED_MODULE_0__["Component"])({
            selector: 'app-root',
            template: __webpack_require__(/*! ./app.component.html */ "./src/app/app.component.html"),
            styles: [__webpack_require__(/*! ./app.component.css */ "./src/app/app.component.css")]
        }),
        __metadata("design:paramtypes", [])
    ], AppComponent);
    return AppComponent;
}());



/***/ }),

/***/ "./src/app/app.module.ts":
/*!*******************************!*\
  !*** ./src/app/app.module.ts ***!
  \*******************************/
/*! exports provided: AppModule */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "AppModule", function() { return AppModule; });
/* harmony import */ var _angular_platform_browser__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @angular/platform-browser */ "./node_modules/@angular/platform-browser/fesm5/platform-browser.js");
/* harmony import */ var _angular_core__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @angular/core */ "./node_modules/@angular/core/fesm5/core.js");
/* harmony import */ var _angular_platform_browser_animations__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @angular/platform-browser/animations */ "./node_modules/@angular/platform-browser/fesm5/animations.js");
/* harmony import */ var _angular_common_http__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! @angular/common/http */ "./node_modules/@angular/common/fesm5/http.js");
/* harmony import */ var _angular_forms__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! @angular/forms */ "./node_modules/@angular/forms/fesm5/forms.js");
/* harmony import */ var _mat_mymat_module__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! ../mat/mymat.module */ "./src/mat/mymat.module.ts");
/* harmony import */ var _app_component__WEBPACK_IMPORTED_MODULE_6__ = __webpack_require__(/*! ./app.component */ "./src/app/app.component.ts");
/* harmony import */ var _job_searcher_job_searcher_component__WEBPACK_IMPORTED_MODULE_7__ = __webpack_require__(/*! ./job-searcher/job-searcher.component */ "./src/app/job-searcher/job-searcher.component.ts");
/* harmony import */ var _service_rest_interceptor_service__WEBPACK_IMPORTED_MODULE_8__ = __webpack_require__(/*! ./service/rest-interceptor.service */ "./src/app/service/rest-interceptor.service.ts");
var __decorate = (undefined && undefined.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};









var AppModule = /** @class */ (function () {
    function AppModule() {
    }
    AppModule = __decorate([
        Object(_angular_core__WEBPACK_IMPORTED_MODULE_1__["NgModule"])({
            declarations: [
                _app_component__WEBPACK_IMPORTED_MODULE_6__["AppComponent"],
                _job_searcher_job_searcher_component__WEBPACK_IMPORTED_MODULE_7__["JobSearcherComponent"]
            ],
            imports: [
                _angular_platform_browser__WEBPACK_IMPORTED_MODULE_0__["BrowserModule"],
                _angular_platform_browser_animations__WEBPACK_IMPORTED_MODULE_2__["BrowserAnimationsModule"],
                _angular_common_http__WEBPACK_IMPORTED_MODULE_3__["HttpClientModule"],
                _angular_forms__WEBPACK_IMPORTED_MODULE_4__["FormsModule"],
                _mat_mymat_module__WEBPACK_IMPORTED_MODULE_5__["MymatModule"]
            ],
            providers: [{
                    provide: _angular_common_http__WEBPACK_IMPORTED_MODULE_3__["HTTP_INTERCEPTORS"],
                    useClass: _service_rest_interceptor_service__WEBPACK_IMPORTED_MODULE_8__["RestInterceptorService"],
                    multi: true
                }],
            bootstrap: [_app_component__WEBPACK_IMPORTED_MODULE_6__["AppComponent"]]
        })
    ], AppModule);
    return AppModule;
}());



/***/ }),

/***/ "./src/app/job-searcher/job-searcher.component.css":
/*!*********************************************************!*\
  !*** ./src/app/job-searcher/job-searcher.component.css ***!
  \*********************************************************/
/*! no static exports found */
/***/ (function(module, exports) {

module.exports = ".zmf-ext-input-s {\r\n  width: 8rem;\r\n  min-width: 5rem;\r\n}\r\n\r\n.zmf-ext-label-inline {\r\n  margin-bottom: 0;\r\n  margin-right: 1rem;\r\n}\r\n\r\n.zmf-ext-div-flex-row-even {\r\n  display: flex;\r\n  flex-direction: row;\r\n  justify-content: space-evenly;\r\n  flex: 1;\r\n}\r\n\r\n.zmf-ext-div-flex-row-center {\r\n  display: flex;\r\n  flex-direction: row;\r\n  align-items: center;\r\n}\r\n\r\n.zmf-ext-table-padding {\r\n  padding: 2rem;\r\n}"

/***/ }),

/***/ "./src/app/job-searcher/job-searcher.component.html":
/*!**********************************************************!*\
  !*** ./src/app/job-searcher/job-searcher.component.html ***!
  \**********************************************************/
/*! no static exports found */
/***/ (function(module, exports) {

module.exports = "<div class=\"bx--data-table-v2-container zmf-ext-table-padding\" data-table-v2>\n  <h4 class=\"bx--data-table-v2-header\">Jobs</h4>\n  <section class=\"bx--table-toolbar\">\n    <!--\n    <div class=\"bx--toolbar-search-container\">\n      <div data-search class=\"bx--search bx--search--sm bx--search--light\" role=\"search\">\n        <svg class=\"bx--search-magnifier\" width=\"16\" height=\"16\" viewBox=\"0 0 16 16\">\n          <path d=\"M6.5 12a5.5 5.5 0 1 0 0-11 5.5 5.5 0 0 0 0 11zm4.936-1.27l4.563 4.557-.707.708-4.563-4.558a6.5 6.5 0 1 1 .707-.707z\"\n            fill-rule=\"nonzero\" />\n        </svg>\n        <label id=\"search-input-label-1\" class=\"bx--label\" for=\"search__input-2\">Search</label>\n        <input class=\"bx--search-input\" type=\"text\" id=\"search__input-2\" role=\"search\" placeholder=\"Search\"\n          aria-labelledby=\"search-input-label-1\">\n        <button class=\"bx--search-close bx--search-close--hidden\" title=\"Clear search\n        input\" aria-label=\"Clear search input\">\n          <svg width=\"16\" height=\"16\" viewBox=\"0 0 16 16\" xmlns=\"http://www.w3.org/2000/svg\">\n            <path d=\"M8 6.586L5.879 4.464 4.464 5.88 6.586 8l-2.122 2.121 1.415 1.415L8 9.414l2.121 2.122 1.415-1.415L9.414 8l2.122-2.121-1.415-1.415L8 6.586zM8 16A8 8 0 1 1 8 0a8 8 0 0 1 0 16z\"\n              fill-rule=\"evenodd\" />\n          </svg>\n        </button>\n      </div>\n    </div>\n    -->\n\n    <!-- <div class=\"bx--toolbar-content\"> -->\n    <div class=\"zmf-ext-div-flex-row-even\">\n      <div class=\"bx--radio-button-group\">\n        <label class=\"bx--label zmf-ext-label-inline\">Prefix:</label>\n        <input id=\"text-input-2\" type=\"text\" class=\"bx--text-input zmf-ext-input-s\" placeholder=\"prefix\" [(ngModel)]=\"prefix\">\n      </div>\n      <div class=\"bx--radio-button-group\">\n        <label class=\"bx--label zmf-ext-label-inline\">Owned By:</label>\n        <input id=\"text-input-2\" type=\"text\" class=\"bx--text-input zmf-ext-input-s\" placeholder=\"userid\" [(ngModel)]=\"owner\">\n        <!-- <input id=\"text-input-2\" type=\"text\" class=\"bx--text-input zmf-ext-input-s\" placeholder=\"userid\" disabled> -->\n      </div>\n    </div>\n    <div class=\"zmf-ext-div-flex-row-center\">\n      <button class=\"bx--toolbar-action\" [matMenuTriggerFor]=\"menu\" >\n        <svg width=\"24\" height=\"24\" viewBox=\"0 0 24 24\">\n          <path d=\"M14 1v22H1V1h13zm1-1H0v24h15V0zm8 1v22h-5V1h5zm1-1h-7v24h7V0z\"></path>\n          <path d=\"M12 4v4H3V4h9zm1-1H2v6h11V3zm8 0v1h-1V3h1zm1-1h-3v3h3V2zm-1 5v1h-1V7h1zm1-1h-3v3h3V6zm-1 5v1h-1v-1h1zm1-1h-3v3h3v-3zm-1 5v1h-1v-1h1zm1-1h-3v3h3v-3zm-1 5v1h-1v-1h1zm1-1h-3v3h3v-3z\"></path>\n        </svg>\n      </button>\n      <mat-menu #menu=\"matMenu\">\n        <button mat-menu-item (click)=\"save2Server()\">save to remote server</button>\n        <button mat-menu-item (click)=\"refreshFromServer()\">retrieve from remote server</button>\n      </mat-menu>\n      <button class=\"bx--btn bx--btn--sm bx--btn--primary\" (click)=\"retrieveJobs()\">Retrieve</button>\n    </div>\n  </section>\n\n  <table class=\"bx--data-table-v2\">\n    <thead>\n      <tr>\n        <th>\n          <button class=\"bx--table-sort-v2\" data-event=\"sort\">\n            <span class=\"bx--table-header-label\">Job Name</span>\n            <svg class=\"bx--table-sort-v2__icon\" width=\"10\" height=\"5\" viewBox=\"0 0 10 5\">\n              <path d=\"M0 0l5 4.998L10 0z\" fill-rule=\"evenodd\" />\n            </svg>\n          </button>\n        </th>\n        <th>\n          <button class=\"bx--table-sort-v2\" data-event=\"sort\">\n            <span>Job ID</span>\n            <svg class=\"bx--table-sort-v2__icon\" width=\"10\" height=\"5\" viewBox=\"0 0 10 5\">\n              <path d=\"M0 0l5 4.998L10 0z\" fill-rule=\"evenodd\" />\n            </svg>\n          </button>\n        </th>\n        <th>\n          <button class=\"bx--table-sort-v2\" data-event=\"sort\">\n            <span>Owner</span>\n            <svg class=\"bx--table-sort-v2__icon\" width=\"10\" height=\"5\" viewBox=\"0 0 10 5\">\n              <path d=\"M0 0l5 4.998L10 0z\" fill-rule=\"evenodd\" />\n            </svg>\n          </button>\n        </th>\n        <th>\n          <button class=\"bx--table-sort-v2\" data-event=\"sort\">\n            <span>Status</span>\n            <svg class=\"bx--table-sort-v2__icon\" width=\"10\" height=\"5\" viewBox=\"0 0 10 5\">\n              <path d=\"M0 0l5 4.998L10 0z\" fill-rule=\"evenodd\" />\n            </svg>\n          </button>\n        </th>\n        <th>\n          <button class=\"bx--table-sort-v2\" data-event=\"sort\">\n            <span>Return Code</span>\n            <svg class=\"bx--table-sort-v2__icon\" width=\"10\" height=\"5\" viewBox=\"0 0 10 5\">\n              <path d=\"M0 0l5 4.998L10 0z\" fill-rule=\"evenodd\" />\n            </svg>\n          </button>\n        </th>\n        <th>\n          <button class=\"bx--table-sort-v2\" data-event=\"sort\">\n            <span>Class</span>\n            <svg class=\"bx--table-sort-v2__icon\" width=\"10\" height=\"5\" viewBox=\"0 0 10 5\">\n              <path d=\"M0 0l5 4.998L10 0z\" fill-rule=\"evenodd\" />\n            </svg>\n          </button>\n        </th>\n        <th></th>\n      </tr>\n    </thead>\n    <!-- Job Name, Job ID, Owner, Status, Return Code, Class-->\n    <tbody>\n      <tr *ngFor=\"let job of jobs\">\n        <td>{{job.jobname}}</td>\n        <td>{{job.jobid}}</td>\n        <td>{{job.owner}}</td>\n        <td>{{job.status}}</td>\n        <td>{{job.retcode}}</td>\n        <td>{{job.clazz}}</td>\n        <td class=\"bx--table-overflow\">\n          <div data-overflow-menu tabindex=\"0\" aria-label=\"Overflow menu description\" class=\"bx--overflow-menu\">\n            <svg class=\"bx--overflow-menu__icon\" width=\"3\" height=\"15\" viewBox=\"0 0 3 15\">\n              <g fill-rule=\"evenodd\">\n                <circle cx=\"1.5\" cy=\"1.5\" r=\"1.5\" />\n                <circle cx=\"1.5\" cy=\"7.5\" r=\"1.5\" />\n                <circle cx=\"1.5\" cy=\"13.5\" r=\"1.5\" />\n              </g>\n            </svg>\n            <ul class=\"bx--overflow-menu-options bx--overflow-menu--flip\">\n              <li class=\"bx--overflow-menu-options__option\">\n                <button class=\"bx--overflow-menu-options__btn\">Stop app</button>\n              </li>\n              <li class=\"bx--overflow-menu-options__option\">\n                <button class=\"bx--overflow-menu-options__btn\">Restart app</button>\n              </li>\n              <li class=\"bx--overflow-menu-options__option\">\n                <button class=\"bx--overflow-menu-options__btn\">Rename app</button>\n              </li>\n              <li class=\"bx--overflow-menu-options__option\">\n                <button class=\"bx--overflow-menu-options__btn\">Edit routes and access, use title when</button>\n              </li>\n              <li class=\"bx--overflow-menu-options__option bx--overflow-menu-options__option--danger\">\n                <button class=\"bx--overflow-menu-options__btn\">Delete app</button>\n              </li>\n            </ul>\n          </div>\n        </td>\n      </tr>\n    </tbody>\n  </table>\n</div>\n<!--\n<div class=\"bx--pagination\" data-pagination>\n  <div class=\"bx--pagination__left\">\n    <span class=\"bx--pagination__text\">Items per page:</span>\n    <div class=\"bx--select bx--select--inline\">\n      <label for=\"select-id-pagination\" class=\"bx--visually-hidden\">Number of items per page</label>\n      <select id=\"select-id-pagination\" class=\"bx--select-input\" data-items-per-page>\n        <option class=\"bx--select-option\" value=\"10\" selected>10</option>\n        <option class=\"bx--select-option\" value=\"20\">20</option>\n        <option class=\"bx--select-option\" value=\"30\">30</option>\n        <option class=\"bx--select-option\" value=\"40\">40</option>\n        <option class=\"bx--select-option\" value=\"50\">50</option>\n      </select>\n      <svg class=\"bx--select__arrow\" width=\"10\" height=\"5\" viewBox=\"0 0 10 5\">\n        <path d=\"M0 0l5 4.998L10 0z\" fill-rule=\"evenodd\" />\n      </svg>\n    </div>\n    <span class=\"bx--pagination__text\">\n      <span>|&nbsp;</span>\n      <span data-displayed-item-range>1-10</span> of\n      <span data-total-items>40</span> items</span>\n  </div>\n  <div class=\"bx--pagination__right bx--pagination--inline\">\n    <span class=\"bx--pagination__text\">\n      <span data-displayed-page-number>1</span> of\n      <span data-total-pages>4</span> pages</span>\n    <button class=\"bx--pagination__button bx--pagination__button--backward\" data-page-backward aria-label=\"Backward button\">\n      <svg class=\"bx--pagination__button-icon\" width=\"7\" height=\"12\" viewBox=\"0 0 7 12\">\n        <path fill-rule=\"nonzero\" d=\"M1.45 6.002L7 11.27l-.685.726L0 6.003 6.315 0 7 .726z\" />\n      </svg>\n    </button>\n    <label for=\"page-number-input\" class=\"bx--visually-hidden\">Page number input</label>\n    <div class=\"bx--select bx--select--inline\">\n      <label for=\"select-id-pagination\" class=\"bx--visually-hidden\">Number of items per page</label>\n      <select id=\"select-id-pagination\" class=\"bx--select-input\" data-page-number-input>\n        <option class=\"bx--select-option\" value=\"1\" selected>1</option>\n        <option class=\"bx--select-option\" value=\"2\">2</option>\n        <option class=\"bx--select-option\" value=\"3\">3</option>\n        <option class=\"bx--select-option\" value=\"4\">4</option>\n        <option class=\"bx--select-option\" value=\"5\">5</option>\n      </select>\n      <svg class=\"bx--select__arrow\" width=\"10\" height=\"5\" viewBox=\"0 0 10 5\">\n        <path d=\"M0 0l5 4.998L10 0z\" fill-rule=\"evenodd\" />\n      </svg>\n    </div>\n    <button class=\"bx--pagination__button bx--pagination__button--forward\" data-page-forward aria-label=\"Forward button\">\n      <svg class=\"bx--pagination__button-icon\" width=\"7\" height=\"12\" viewBox=\"0 0 7 12\">\n        <path fill-rule=\"nonzero\" d=\"M5.569 5.994L0 .726.687 0l6.336 5.994-6.335 6.002L0 11.27z\" />\n      </svg>\n    </button>\n  </div>\n</div>\n-->"

/***/ }),

/***/ "./src/app/job-searcher/job-searcher.component.ts":
/*!********************************************************!*\
  !*** ./src/app/job-searcher/job-searcher.component.ts ***!
  \********************************************************/
/*! exports provided: JobSearcherComponent */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "JobSearcherComponent", function() { return JobSearcherComponent; });
/* harmony import */ var _angular_core__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @angular/core */ "./node_modules/@angular/core/fesm5/core.js");
/* harmony import */ var _service_job_service__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ../service/job.service */ "./src/app/service/job.service.ts");
/* harmony import */ var _service_app_route_service__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../service/app-route.service */ "./src/app/service/app-route.service.ts");
/* harmony import */ var _job_job__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! ../job/job */ "./src/app/job/job.ts");
var __decorate = (undefined && undefined.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (undefined && undefined.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};




var JobSearcherComponent = /** @class */ (function () {
    // parent.currentUserName
    function JobSearcherComponent(_jobService, _appService) {
        this._jobService = _jobService;
        this._appService = _appService;
        this.jobs = new Array(0);
    }
    JobSearcherComponent.prototype.ngOnInit = function () {
        var _this = this;
        // get jobs list from zos
        this._jobService.listJobs(null, null).subscribe(function (jobsData) {
            if (jobsData && jobsData.length > 0) {
                _this.jsonArray2Jobs(jobsData);
            }
            else {
                console.log("response of geting jobs is empty");
            }
        }, function (error) { return console.log(error); });
    };
    JobSearcherComponent.prototype.retrieveJobs = function () {
        var _this = this;
        // get jobs list from zos based on user input
        this._jobService.listJobs(this.prefix, this.owner).subscribe(function (jobsData) {
            // clear previous list
            _this.jobs = new Array(0);
            if (jobsData && jobsData.length > 0) {
                _this.jsonArray2Jobs(jobsData);
            }
            else {
                console.log("response of geting jobs is empty");
            }
        }, function (error) { return console.log("get job error: " + error); });
    };
    // json array contains at least one job
    JobSearcherComponent.prototype.jsonArray2Jobs = function (jArray) {
        var jobname;
        var jobid;
        var owner;
        var status;
        var retcode;
        var clazz;
        for (var _i = 0, jArray_1 = jArray; _i < jArray_1.length; _i++) {
            var jobData = jArray_1[_i];
            jobname = jobData["jobname"];
            jobid = jobData["jobid"];
            owner = jobData["owner"];
            status = jobData["status"];
            retcode = jobData["retcode"];
            clazz = jobData["class"];
            var job = new _job_job__WEBPACK_IMPORTED_MODULE_3__["Job"](jobname, jobid, owner, status, retcode, clazz);
            this.jobs.push(job);
        }
    };
    JobSearcherComponent.prototype.save2Server = function () {
        this._appService.updateData(this.prefix, this.owner).subscribe(function (data) { }, function (error) { return console.log("put server error: " + error); });
    };
    JobSearcherComponent.prototype.refreshFromServer = function () {
        var _this = this;
        this._appService.retrieveData().subscribe(function (profileData) {
            if (profileData && profileData.length != 0) {
                _this.prefix = profileData["prefix"];
                _this.owner = profileData["owner"];
            }
        }, function (error) { return console.log("get server error: " + error); });
    };
    JobSearcherComponent = __decorate([
        Object(_angular_core__WEBPACK_IMPORTED_MODULE_0__["Component"])({
            selector: 'app-job-searcher',
            template: __webpack_require__(/*! ./job-searcher.component.html */ "./src/app/job-searcher/job-searcher.component.html"),
            styles: [__webpack_require__(/*! ./job-searcher.component.css */ "./src/app/job-searcher/job-searcher.component.css")]
        }),
        __metadata("design:paramtypes", [_service_job_service__WEBPACK_IMPORTED_MODULE_1__["JobService"], _service_app_route_service__WEBPACK_IMPORTED_MODULE_2__["AppRouteService"]])
    ], JobSearcherComponent);
    return JobSearcherComponent;
}());



/***/ }),

/***/ "./src/app/job/job.ts":
/*!****************************!*\
  !*** ./src/app/job/job.ts ***!
  \****************************/
/*! exports provided: Job */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "Job", function() { return Job; });
var Job = /** @class */ (function () {
    // url: String;
    // filesUrl: String;
    function Job(jobname, jobid, owner, status, retcode, clazz) {
        this.jobid = jobid;
        this.jobname = jobname;
        // this.subsystem = subsys;
        this.owner = owner;
        this.status = status;
        // this.type = type;
        this.clazz = clazz;
        this.retcode = retcode;
        // this.url = url;
        // this.filesUrl = filesUrl;
    }
    return Job;
}());



/***/ }),

/***/ "./src/app/service/app-route.service.ts":
/*!**********************************************!*\
  !*** ./src/app/service/app-route.service.ts ***!
  \**********************************************/
/*! exports provided: AppRouteService */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "AppRouteService", function() { return AppRouteService; });
/* harmony import */ var _angular_core__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @angular/core */ "./node_modules/@angular/core/fesm5/core.js");
/* harmony import */ var _angular_common_http__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @angular/common/http */ "./node_modules/@angular/common/fesm5/http.js");
var __decorate = (undefined && undefined.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (undefined && undefined.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};


var AppRouteService = /** @class */ (function () {
    function AppRouteService(http) {
        this.http = http;
        this.routeUrl = '/externalgateway/system';
        this.remoteSys = 'mySys';
        this.resourcePath = '/profile';
        this.parmContent = '{"target":"' + this.remoteSys +
            '","resourcePath":"' + this.resourcePath + '","wrapped":"N"}';
        this.url = this.routeUrl + "?content=" + this.parmContent;
    }
    AppRouteService.prototype.retrieveData = function () {
        // GET host:port/zosmf/externalgateway/system?content={"target":"mySys","resourcePath":"/profile","wrapped":"N"}
        return this.http.get(this.url);
    };
    AppRouteService.prototype.updateData = function (prefix, owner) {
        // PUT host:port/zosmf/externalgateway/system
        // {
        //   "target": "mySys",
        //   "resourcePath": "/profile",
        //   "content": {
        //     "prefix": "<prefix>",
        //     "owner": "<owner>"
        //   }
        // }
        var content = new Object();
        content["owner"] = owner;
        content["prefix"] = prefix;
        var body = new Object();
        body["target"] = this.remoteSys;
        body["resourcePath"] = this.resourcePath;
        body["content"] = content;
        return this.http.put(this.routeUrl, JSON.stringify(body));
    };
    AppRouteService = __decorate([
        Object(_angular_core__WEBPACK_IMPORTED_MODULE_0__["Injectable"])({
            providedIn: 'root'
        }),
        __metadata("design:paramtypes", [_angular_common_http__WEBPACK_IMPORTED_MODULE_1__["HttpClient"]])
    ], AppRouteService);
    return AppRouteService;
}());



/***/ }),

/***/ "./src/app/service/job.service.ts":
/*!****************************************!*\
  !*** ./src/app/service/job.service.ts ***!
  \****************************************/
/*! exports provided: JobService */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "JobService", function() { return JobService; });
/* harmony import */ var _angular_core__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @angular/core */ "./node_modules/@angular/core/fesm5/core.js");
/* harmony import */ var _angular_common_http__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @angular/common/http */ "./node_modules/@angular/common/fesm5/http.js");
/* harmony import */ var _job_job__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ../job/job */ "./src/app/job/job.ts");
var __decorate = (undefined && undefined.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (undefined && undefined.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};



var JobService = /** @class */ (function () {
    function JobService(http) {
        this.http = http;
        this.jobs = new Array(0);
        this.jobsUrl = "/restjobs/jobs";
        for (var i = 0; i < 8; i++) {
            var job = new _job_job__WEBPACK_IMPORTED_MODULE_2__["Job"]('TESTJOB', 'JOB00023', 'IBMUSER', 'OUTPUT', 'CC 0000', 'A');
            this.jobs.push(job);
        }
    }
    JobService.prototype.listJobs = function (prefix, owner) {
        // return this.jobs;
        var url = this.jobsUrl;
        var hasParm = false;
        if (prefix != null && prefix.length != 0) {
            url = url + "?prefix=" + prefix;
            hasParm = true;
        }
        if (owner != null && owner.length != 0) {
            if (hasParm)
                url = url + "&owner=" + owner;
            else
                url = url + "?owner=" + owner;
        }
        return this.http.get(url);
    };
    JobService = __decorate([
        Object(_angular_core__WEBPACK_IMPORTED_MODULE_0__["Injectable"])({
            providedIn: 'root'
        }),
        __metadata("design:paramtypes", [_angular_common_http__WEBPACK_IMPORTED_MODULE_1__["HttpClient"]])
    ], JobService);
    return JobService;
}());



/***/ }),

/***/ "./src/app/service/rest-interceptor.service.ts":
/*!*****************************************************!*\
  !*** ./src/app/service/rest-interceptor.service.ts ***!
  \*****************************************************/
/*! exports provided: RestInterceptorService */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "RestInterceptorService", function() { return RestInterceptorService; });
/* harmony import */ var _angular_core__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @angular/core */ "./node_modules/@angular/core/fesm5/core.js");
/* harmony import */ var _angular_common_http__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @angular/common/http */ "./node_modules/@angular/common/fesm5/http.js");
var __decorate = (undefined && undefined.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (undefined && undefined.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};


var RestInterceptorService = /** @class */ (function () {
    function RestInterceptorService() {
        var location = window.location.href;
        if (location.indexOf('localhost') > 0) {
            this.baseUrl = 'https://pev076.pok.ibm.com/zosmf';
            this.headers = new _angular_common_http__WEBPACK_IMPORTED_MODULE_1__["HttpHeaders"]({
                'Authorization': 'Basic aWJtdXNlcjpzeXMx',
                'X-CSRF-ZOSMF-HEADER': 'zosmf'
            });
        }
        else {
            this.baseUrl = '/zosmf';
        }
    }
    RestInterceptorService.prototype.intercept = function (req, next) {
        // copy requester's header
        if (req.headers != null && req.headers.keys() != null) {
            var keys = req.headers.keys();
            var key = void 0, value = void 0;
            for (var i in keys) {
                key = keys[i];
                value = req.headers.get(key);
                this.headers.set(key, value);
            }
        }
        var cloneReq = req.clone({
            url: "" + this.baseUrl + req.url,
            headers: this.headers
        });
        return next.handle(cloneReq);
    };
    RestInterceptorService = __decorate([
        Object(_angular_core__WEBPACK_IMPORTED_MODULE_0__["Injectable"])({
            providedIn: 'root'
        }),
        __metadata("design:paramtypes", [])
    ], RestInterceptorService);
    return RestInterceptorService;
}());



/***/ }),

/***/ "./src/environments/environment.ts":
/*!*****************************************!*\
  !*** ./src/environments/environment.ts ***!
  \*****************************************/
/*! exports provided: environment */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "environment", function() { return environment; });
// This file can be replaced during build by using the `fileReplacements` array.
// `ng build ---prod` replaces `environment.ts` with `environment.prod.ts`.
// The list of file replacements can be found in `angular.json`.
var environment = {
    production: false
};
/*
 * In development mode, for easier debugging, you can ignore zone related error
 * stack frames such as `zone.run`/`zoneDelegate.invokeTask` by importing the
 * below file. Don't forget to comment it out in production mode
 * because it will have a performance impact when errors are thrown
 */
// import 'zone.js/dist/zone-error';  // Included with Angular CLI.


/***/ }),

/***/ "./src/main.ts":
/*!*********************!*\
  !*** ./src/main.ts ***!
  \*********************/
/*! no exports provided */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var hammerjs__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! hammerjs */ "./node_modules/hammerjs/hammer.js");
/* harmony import */ var hammerjs__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(hammerjs__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _angular_core__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @angular/core */ "./node_modules/@angular/core/fesm5/core.js");
/* harmony import */ var _angular_platform_browser_dynamic__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @angular/platform-browser-dynamic */ "./node_modules/@angular/platform-browser-dynamic/fesm5/platform-browser-dynamic.js");
/* harmony import */ var _app_app_module__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! ./app/app.module */ "./src/app/app.module.ts");
/* harmony import */ var _environments_environment__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! ./environments/environment */ "./src/environments/environment.ts");





if (_environments_environment__WEBPACK_IMPORTED_MODULE_4__["environment"].production) {
    Object(_angular_core__WEBPACK_IMPORTED_MODULE_1__["enableProdMode"])();
}
Object(_angular_platform_browser_dynamic__WEBPACK_IMPORTED_MODULE_2__["platformBrowserDynamic"])().bootstrapModule(_app_app_module__WEBPACK_IMPORTED_MODULE_3__["AppModule"])
    .catch(function (err) { return console.log(err); });


/***/ }),

/***/ "./src/mat/mymat.module.ts":
/*!*********************************!*\
  !*** ./src/mat/mymat.module.ts ***!
  \*********************************/
/*! exports provided: MymatModule */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, "MymatModule", function() { return MymatModule; });
/* harmony import */ var _angular_core__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! @angular/core */ "./node_modules/@angular/core/fesm5/core.js");
/* harmony import */ var _angular_material_menu__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! @angular/material/menu */ "./node_modules/@angular/material/esm5/menu.es5.js");
var __decorate = (undefined && undefined.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};


var MymatModule = /** @class */ (function () {
    function MymatModule() {
    }
    MymatModule = __decorate([
        Object(_angular_core__WEBPACK_IMPORTED_MODULE_0__["NgModule"])({
            imports: [
                _angular_material_menu__WEBPACK_IMPORTED_MODULE_1__["MatMenuModule"]
            ],
            exports: [
                _angular_material_menu__WEBPACK_IMPORTED_MODULE_1__["MatMenuModule"]
            ]
        })
    ], MymatModule);
    return MymatModule;
}());



/***/ }),

/***/ 0:
/*!***************************!*\
  !*** multi ./src/main.ts ***!
  \***************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

module.exports = __webpack_require__(/*! D:\work-space\git-space\ExternalPluginExample-RemoteServer\src\main.ts */"./src/main.ts");


/***/ })

},[[0,"runtime","vendor"]]]);
//# sourceMappingURL=main.js.map