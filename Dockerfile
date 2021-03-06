FROM bkimminich/juice-shop:v13.0.0
USER root

RUN apk update && apk add --no-cache \
		bash \
        g++ \
        gcc \
        make \
        python3

RUN npm install tcell-agent --save
RUN sed -i "1i require('tcell-agent');" build/app.js

RUN npm install tcell-hooks --save

# UPDATING LOGIN ROUTE TO USE TCELL HOOKS

#This one is hard to do since there is a two matching before and after lines. Insert at specific line number before other lines are inserted.
RUN sed -i "51i \\\t \ \ \ \TCellHooks.sendExpressLoginEventFailure(req, req.body.email, req.cookies.io)" build/routes/login.js

RUN sed -i "8i const TCellHooks = require('tcell-hooks').v1" build/routes/login.js

# Add req to afterLogin params
RUN sed -i "s|function afterLogin(user, res, next) {|function afterLogin(req, user, res, next) {|" build/routes/login.js

# Send loginEventSuccess after this line
RUN sed -i "/security.authenticatedUsers.put(token, user)/a \\\t\ \ \ \ TCellHooks.sendExpressLoginEventSuccess(req, user.data.email, token)" build/routes/login.js

# Send loginEventSuccess before this line
RUN sed -i "/res.status(401).json({/i \\\t\t\TCellHooks.sendExpressLoginEventSuccess(req, user.data.email, token)" build/routes/login.js

# Include extra req param when calling afterLogin
RUN sed -i "s|afterLogin(user, res, next)|afterLogin(req, user, res, next)|" build/routes/login.js

# Send loginFailureEvent before this line
RUN sed -i "/res.status(401).send(res.__('Invalid email or password.'))/i \\\t\tTCellHooks.sendExpressLoginEventFailure(req, req.body.email, req.cookies.io)" build/routes/login.js

COPY tcell_agent.config .
