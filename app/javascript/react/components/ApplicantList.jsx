import React from "react";
import { observer } from "mobx-react-lite";
import Applicant from "./Applicant";

export default observer(({
  applicants,
  isDepartmentLevel,
  downloadInProgress,
  setDownloadInProgress,
  showReferentColumn,
  showCarnetColumn,
}) => applicants.map((applicant) => (
    <Applicant
      applicant={applicant}
      isDepartmentLevel={isDepartmentLevel}
      downloadInProgress={downloadInProgress}
      setDownloadInProgress={setDownloadInProgress}
      key={applicant.departmentInternalId || applicant.uid}
      showReferentColumn={showReferentColumn}
      showCarnetColumn={showCarnetColumn}
    />
  )));