<%--
  ~ Copyright (c) 2015, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~ WSO2 Inc. licenses this file to you under the Apache License,
  ~ Version 2.0 (the "License"); you may not use this file except
  ~ in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied.  See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
  --%>

<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib uri="http://wso2.org/projects/carbon/taglibs/carbontags.jar"
           prefix="carbon" %>
<%@ page import="org.apache.axis2.AxisFault" %>
<%@ page import="org.apache.axis2.context.ConfigurationContext" %>
<%@ page import="org.apache.commons.lang.StringUtils" %>
<%@ page import="org.wso2.carbon.CarbonConstants" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.stub.WorkflowAdminServiceWorkflowException" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.ui.WorkflowAdminServiceClient" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.ui.WorkflowUIConstants" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIMessage" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIUtil" %>

<%@ page import="org.wso2.carbon.utils.ServerConstants" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ResourceBundle" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.stub.bean.WorkflowRequest" %>
<%@ page import="org.wso2.carbon.identity.workflow.mgt.stub.metadata.WorkflowEvent" %>
<jsp:include page="../dialog/display_messages.jsp"/>

<script type="text/javascript" src="extensions/js/vui.js"></script>
<script type="text/javascript" src="../extensions/core/js/vui.js"></script>
<script type="text/javascript" src="../admin/js/main.js"></script>

<%
    String taskTypeFilter = request.getParameter("requestTypeFilter");
    String statusToFilter = request.getParameter("requestStatusFilter");
    String lowerBound = request.getParameter("createdAtFrom");
    String upperBound = request.getParameter("createdAtTo");
    String timeFilterCategory = request.getParameter("timeCategoryToFilter");
    String loggedUser = (String) session.getAttribute("logged-user");
    String bundle = "org.wso2.carbon.identity.workflow.mgt.ui.i18n.Resources";
    ResourceBundle resourceBundle = ResourceBundle.getBundle(bundle, request.getLocale());
    WorkflowAdminServiceClient client;
    String forwardTo = null;
    WorkflowRequest[] associationToDisplay = new WorkflowRequest[0];
    WorkflowRequest[] requestList = null;
    String paginationValue = "region=region1";

    String pageNumber = request.getParameter(WorkflowUIConstants.PARAM_PAGE_NUMBER);
    int pageNumberInt = 0;
    int numberOfPages = 0;
    WorkflowEvent[] workflowEvents;
    Map<String, List<WorkflowEvent>> events = new HashMap<String, List<WorkflowEvent>>();

    if (pageNumber != null) {
        try {
            pageNumberInt = Integer.parseInt(pageNumber);
        } catch (NumberFormatException ignored) {
            //not needed here since it's defaulted to 0
        }
    }
    try {
        String cookie = (String) session.getAttribute(ServerConstants.ADMIN_SERVICE_COOKIE);
        String backendServerURL = CarbonUIUtil.getServerURL(config.getServletContext(), session);
        ConfigurationContext configContext =
                (ConfigurationContext) config.getServletContext()
                        .getAttribute(CarbonConstants.CONFIGURATION_CONTEXT);
        client = new WorkflowAdminServiceClient(cookie, backendServerURL, configContext);

        if (taskTypeFilter == null) {
            taskTypeFilter = "";
        }
        if (statusToFilter == null) {
            statusToFilter = "";
        }
        if (lowerBound == null) {
            lowerBound = "";
        }
        if (upperBound == null) {
            upperBound = "";
        }
        if (timeFilterCategory == null) {
            timeFilterCategory = "createdAt";
        }


        if (taskTypeFilter.equals("allTasks")) {
            requestList = client.getAllRequests(lowerBound, upperBound, timeFilterCategory);
        } else {
            requestList = client.getRequestsCreatedByUser(loggedUser, lowerBound, upperBound, timeFilterCategory);
        }

        if (requestList == null) {
            requestList = new WorkflowRequest[0];
        }

        numberOfPages = (int) Math.ceil((double) requestList.length / WorkflowUIConstants.RESULTS_PER_PAGE);

        int startIndex = pageNumberInt * WorkflowUIConstants.RESULTS_PER_PAGE;
        int endIndex = (pageNumberInt + 1) * WorkflowUIConstants.RESULTS_PER_PAGE;
        associationToDisplay = new WorkflowRequest[WorkflowUIConstants.RESULTS_PER_PAGE];

        for (int i = startIndex, j = 0; i < endIndex && i < requestList.length; i++, j++) {
            associationToDisplay[j] = requestList[i];
        }

        workflowEvents = client.listWorkflowEvents();
        for (WorkflowEvent event : workflowEvents) {
            String category = event.getEventCategory();
            if (!events.containsKey(category)) {
                events.put(category, new ArrayList<WorkflowEvent>());
            }
            events.get(category).add(event);
        }
    } catch (WorkflowAdminServiceWorkflowException e) {
        String message = resourceBundle.getString("workflow.error.when.listing.services");
        CarbonUIMessage.sendCarbonUIMessage(message, CarbonUIMessage.ERROR, request);
        forwardTo = "../admin/error.jsp";
    } catch (AxisFault e) {
        String message = resourceBundle.getString("workflow.error.when.initiating.service.client");
        CarbonUIMessage.sendCarbonUIMessage(message, CarbonUIMessage.ERROR, request);
        forwardTo = "../admin/error.jsp";
    }
%>

<%
    if (forwardTo != null) {
%>
<script type="text/javascript">
    function forward() {
        location.href = "<%=forwardTo%>";
    }
</script>

<script type="text/javascript">
    forward();
</script>
<%
        return;
    }
%>
<fmt:bundle basename="org.wso2.carbon.identity.workflow.mgt.ui.i18n.Resources">
    <carbon:breadcrumb label="view"
                       resourceBundle="org.wso2.carbon.identity.workflow.mgt.ui.i18n.Resources"
                       topPage="false" request="<%=request%>"/>

    <script type="text/javascript" src="../carbon/admin/js/breadcrumbs.js"></script>
    <script type="text/javascript" src="../carbon/admin/js/cookies.js"></script>
    <script type="text/javascript" src="../carbon/admin/js/main.js"></script>
    <link rel="stylesheet" href="/carbon/styles/css/main.css">


    <script type="text/javascript">

        function removeRequest(requestId) {
            function doDelete() {
                location.href = 'wf-request-delete-finish.jsp?<%=WorkflowUIConstants.PARAM_REQUEST_ID%>=' +
                        requestId;
            }

            CARBON.showConfirmationDialog('<fmt:message key="confirmation.request.delete"/> ?',
                    doDelete, null);
        }
        function listWorkflows(requestId) {
            location.href = 'wf-workflows-of-request.jsp?<%=WorkflowUIConstants.PARAM_REQUEST_ID%>=' +
                    requestId;
        }
    </script>
    <script type="text/javascript">
        var eventsObj = {};
        var lastSelectedCategory = '';
        <%
            for (Map.Entry<String,List<WorkflowEvent>> eventCategory : events.entrySet()) {
            %>
        eventsObj["<%=eventCategory.getKey()%>"] = [];
        <%
            for (WorkflowEvent event : eventCategory.getValue()) {
                %>
        var eventObj = {};
        eventObj.displayName = "<%=event.getEventFriendlyName()%>";
        eventObj.value = "<%=event.getEventId()%>";
        eventObj.title = "<%=event.getEventDescription()!=null?event.getEventDescription():""%>";
        eventsObj["<%=eventCategory.getKey()%>"].push(eventObj);
        <%
                    }
            }
        %>

        function updateActions() {
            var categoryDropdown = document.getElementById("categoryDropdown");
            var actionDropdown = document.getElementById("actionDropdown");
            var selectedCategory = categoryDropdown.options[categoryDropdown.selectedIndex].value;
            if (selectedCategory != lastSelectedCategory) {
                var eventsOfCategory = eventsObj[selectedCategory];
                for (var i = 0; i < eventsOfCategory.length; i++) {
                    var opt = document.createElement("option");
                    opt.text = eventsOfCategory[i].displayName;
                    opt.value = eventsOfCategory[i].value;
                    opt.title = eventsOfCategory[i].title;
                    actionDropdown.options.add(opt);
                }
                lastSelectedCategory = selectedCategory;
            }
        }

        function getSelectedRequestType() {
        }
        function getSelectedStatusType() {
        }
        function searchRequests() {
            document.searchForm.submit();
        }

    </script>

    <script>
        $(function () {
            $("#createdAtFrom").datepicker({
                defaultDate: "+1w",
                changeMonth: true,
                numberOfMonths: 1,
                onClose: function (selectedDate) {
                    $("#createdAtTo").datepicker("option", "minDate",
                            new Date($('#createdAtFrom').datepicker("getDate")));
                }
            });
            $("#createdAtTo").datepicker({
                defaultDate: "+1w",
                changeMonth: true,
                numberOfMonths: 1,
                onClose: function (selectedDate) {
                    $("#createdAtFrom").datepicker("option", "maxDate", new
                            Date($('#createdAtTo').datepicker("getDate")));
                }
            });
        });
    </script>

    <div id="middle">
        <h2><fmt:message key='request.list'/></h2>

        <form action="wf-request-list.jsp" name="searchForm" method="post">
            <table id="searchTable" name="searchTable" class="styledLeft" style="border:0;
                                                !important margin-top:10px;margin-bottom:10px;">
                <tr>
                    <td>
                        <table style="border:0; !important">
                            <tbody>
                            <tr style="border:0; !important">
                                <td style="border:0; !important">
                                    <nobr>
                                        <fmt:message key="workflow.request.type"/>
                                        <select name="requestTypeFilter" id="requestTypeFilter"
                                                onchange="getSelectedRequestType();">
                                            <% if (taskTypeFilter.equals("allTasks")) { %>
                                            <option value="myTasks"><fmt:message key="myTasks"/></option>
                                            <option value="allTasks"
                                                    selected="selected"><fmt:message key="allTasks"/></option>
                                            <%} else {%>
                                            <option value="myTasks"
                                                    selected="selected"><fmt:message key="myTasks"/></option>
                                            <option value="allTasks"><fmt:message key="allTasks"/></option>
                                            <% } %>
                                        </select>
                                    </nobr>
                                </td>
                            </tr>
                            </tbody>
                        </table>
                    </td>

                    <td>
                        <table style="border:0; !important">
                            <tbody>
                            <tr style="border:0; !important">
                                <td style="border:0; !important">
                                    <nobr>
                                        <fmt:message key="workflow.request.status"/>
                                        <% if (statusToFilter.equals("PENDING")) { %>

                                        <select name="requestStatusFilter" id="requestStatusFilter"
                                                onchange="getSelectedStatusType();">
                                            <option value="allTasks"><fmt:message key="allTasks"/></option>
                                            <option value="PENDING"
                                                    selected="selected"><fmt:message key="pending"/></option>
                                            <option value="APPROVED"><fmt:message key="approved"/></option>
                                            <option value="REJECTED"><fmt:message key="rejected"/></option>
                                            <option value="FAILED"><fmt:message key="failed"/></option>
                                        </select>

                                        <%} else if (statusToFilter.equals("APPROVED")) { %>

                                        <select name="requestStatusFilter" id="requestStatusFilter"
                                                onchange="getSelectedStatusType();">
                                            <option value="allTasks"><fmt:message key="allTasks"/></option>
                                            <option value="PENDING"><fmt:message key="pending"/></option>
                                            <option value="APPROVED"
                                                    selected="selected"><fmt:message key="approved"/></option>
                                            <option value="REJECTED"><fmt:message key="rejected"/></option>
                                            <option value="FAILED"><fmt:message key="failed"/></option>
                                        </select>

                                        <%} else if (statusToFilter.equals("REJECTED")) { %>

                                        <select name="requestStatusFilter" id="requestStatusFilter"
                                                onchange="getSelectedStatusType();">
                                            <option value="allTasks"><fmt:message key="allTasks"/></option>
                                            <option value="PENDING"><fmt:message key="pending"/></option>
                                            <option value="APPROVED"><fmt:message key="approved"/></option>
                                            <option value="REJECTED"
                                                    selected="selected"><fmt:message key="rejected"/></option>
                                            <option value="FAILED"><fmt:message key="failed"/></option>
                                        </select>

                                        <%} else if (statusToFilter.equals("FAILED")) { %>

                                        <select name="requestStatusFilter" id="requestStatusFilter"
                                                onchange="getSelectedStatusType();">
                                            <option value="allTasks"><fmt:message key="allTasks"/></option>
                                            <option value="PENDING"><fmt:message key="pending"/></option>
                                            <option value="APPROVED"><fmt:message key="approved"/></option>
                                            <option value="REJECTED"><fmt:message key="rejected"/></option>
                                            <option value="FAILED"
                                                    selected="selected"><fmt:message key="failed"/></option>
                                        </select>

                                        <%} else { %>

                                        <select name="requestStatusFilter" id="requestStatusFilter"
                                                onchange="getSelectedStatusType();">
                                            <option value="allTasks"
                                                    selected="selected"><fmt:message key="allTasks"/></option>
                                            <option value="PENDING"><fmt:message key="pending"/></option>
                                            <option value="APPROVED"><fmt:message key="approved"/></option>
                                            <option value="REJECTED"><fmt:message key="rejected"/></option>
                                            <option value="FAILED"><fmt:message key="failed"/></option>
                                        </select>
                                        <%}%>
                                    </nobr>
                                </td>
                            </tr>
                            </tbody>
                        </table>
                    </td>
                    <td>
                        <table style="border:0; !important">
                            <tbody>
                            <tr style="border:0; !important">
                                <td style="border:0; !important">
                                    <nobr>
                                        <% if (timeFilterCategory.equals("updatedAt")) { %>
                                        <select name="timeCategoryToFilter" id="timeCategoryToFilter"
                                                onchange="getSelectedRequestType();">
                                            <option value="createdAt"><fmt:message key="createdAt"/></option>
                                            <option value="updatedAt"
                                                    selected="selected"><fmt:message key="updatedAt"/></option>
                                        </select>
                                        <%} else { %>
                                        <select name="timeCategoryToFilter" id="timeCategoryToFilter"
                                                onchange="getSelectedRequestType();">
                                            <option value="createdAt"
                                                    selected="selected"><fmt:message key="createdAt"/></option>
                                            <option value="updatedAt"><fmt:message key="updatedAt"/></option>
                                        </select>
                                        <%}%>

                                    </nobr>
                                </td>
                            </tr>
                            </tbody>
                        </table>
                    </td>
                    <td>
                        <table style="border:0; !important">
                            <tbody>
                            <tr style="border:0; !important">
                                <td style="border:0; !important">
                                    <nobr>
                                        <label for="createdAtFrom">From</label>
                                        <input type="text" id="createdAtFrom" name="createdAtFrom">
                                        <label for="createdAtTo">to</label>
                                        <input type="text" id="createdAtTo" name="createdAtTo">
                                    </nobr>
                                </td>
                            </tr>
                            </tbody>
                        </table>
                    </td>
                    <td style="border:0; !important">
                        <a class="icon-link" href="#" style="background-image: url(images/search-top.png);"
                           onclick="searchRequests(); return false;"
                           alt="<fmt:message key="search"/>"></a>
                    </td>
                </tr>
            </table>
        </form>

        <div id="workArea">
            <table class="styledLeft" id="servicesTable">
                <thead>
                <tr>
                    <th><fmt:message key="workflow.eventType"/></th>
                    <th><fmt:message key="workflow.createdAt"/></th>
                    <th><fmt:message key="workflow.updatedAt"/></th>
                    <th><fmt:message key="workflow.status"/></th>
                    <th><fmt:message key="workflow.requestParams"/></th>
                    <th><fmt:message key="actions"/></th>
                </tr>
                </thead>
                <tbody>
                <%
                    if (requestList != null && requestList.length > 0) {
                        for (WorkflowRequest workflowReq : associationToDisplay) {
                            if (workflowReq != null && (statusToFilter == null || statusToFilter == ""
                                    || statusToFilter.equals("allTasks") || workflowReq.getStatus().equals(statusToFilter))) {
                %>
                <tr>
                    <td><%=workflowReq.getEventType()%>
                    </td>
                    <td><%=workflowReq.getCreatedAt()%>
                    </td>
                    <td><%=workflowReq.getUpdatedAt()%>
                    </td>

                    <td><%=workflowReq.getStatus()%>
                    </td>
                    <td><%=workflowReq.getRequestParams()%>
                    </td>
                    <td>
                        <a title="<fmt:message key='workflow.request.list.title'/>"
                           onclick="listWorkflows('<%=workflowReq.getRequestId()%>');return false;"
                           href="#" style="background-image: url(images/list.png);"
                           class="icon-link"><fmt:message key='workflows'/></a>
                        <% if (workflowReq.getStatus().equals("PENDING") && workflowReq.getCreatedBy().equals(loggedUser)) { %>
                        <a title="<fmt:message key='workflow.request.delete.title'/>"
                           onclick="removeRequest('<%=workflowReq.getRequestId()%>');return false;"
                           href="#" style="background-image: url(images/delete.gif);"
                           class="icon-link"><fmt:message key='delete'/></a>
                        <% } else { %>

                        <% } %>
                    </td>
                </tr>
                <%
                            }
                        }
                    } else { %>
                <tr>
                    <td colspan="6"><i>No requests found.</i></td>
                </tr>
                <% }
                %>
                </tbody>
            </table>
            <carbon:paginator pageNumber="<%=pageNumberInt%>"
                              numberOfPages="<%=numberOfPages%>"
                              page="wf-request-list.jsp"
                              pageNumberParameterName="<%=WorkflowUIConstants.PARAM_PAGE_NUMBER%>"
                              resourceBundle="org.wso2.carbon.security.ui.i18n.Resources"
                              parameters="<%=paginationValue%>"
                              prevKey="prev" nextKey="next"/>
            <br/>
        </div>
    </div>
</fmt:bundle>