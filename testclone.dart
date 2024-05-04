SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => getPastOrders(),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 30 - 200,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              loading
                                  ? const SpinKitFadingCircle(
                                      color: accentColor,
                                    )
                                  : orders
                                          .where(
                                            (element) =>
                                                element.rider == null &&
                                                element.status == "new",
                                          )
                                          .isEmpty
                                      ? Center(
                                          child: SvgPicture.string(nodatafound),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 25.0,
                                          ),
                                          child: ListView.separated(
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              scrollDirection: Axis.vertical,
                                              itemBuilder: (context, index) {
                                                final order = orders
                                                    .where(
                                                      (element) =>
                                                          element.rider ==
                                                              null &&
                                                          element.status ==
                                                              "new",
                                                    )
                                                    .toList()[index];
                                                final isSelected =
                                                    selectedStates[order.id] ==
                                                            null
                                                        ? false
                                                        : true;
                                                return OrderCard(
                                                  isSelected: isSelected,
                                                  onSelectionChanged:
                                                      (isSelected) {
                                                    print(isSelected);
                                                    onSelectionChanged(
                                                      order.id,
                                                      isSelected,
                                                    );
                                                  },
                                                  data: orders
                                                      .where(
                                                        (element) =>
                                                            element.rider ==
                                                                null &&
                                                            element.status ==
                                                                "new",
                                                      )
                                                      .toList()[index],
                                                  modal: true,
                                                );
                                              },
                                              separatorBuilder:
                                                  (context, index) =>
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                              itemCount: orders
                                                  .where(
                                                    (element) =>
                                                        element.rider == null &&
                                                        element.status == "new",
                                                  )
                                                  .length),
                                        ),
                              loading
                                  ? const SpinKitFadingCircle(
                                      color: accentColor,
                                    )
                                  : orders
                                          .where(
                                            (element) =>
                                                element.rider != null &&
                                                element.status == "processing",
                                          )
                                          .isEmpty
                                      ? Center(
                                          child: SvgPicture.string(nodatafound),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 25,
                                          ),
                                          child: ListView.separated(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            scrollDirection: Axis.vertical,
                                            itemBuilder: (context, index) {
                                              final order = orders
                                                  .where(
                                                    (element) =>
                                                        element.rider != null &&
                                                        element.status ==
                                                            "processing",
                                                  )
                                                  .toList()[index];
                                              final isSelected =
                                                  selectedStates[order.id] ==
                                                          null
                                                      ? false
                                                      : true;
                                              return OrderCard(
                                                isSelected: isSelected,
                                                onSelectionChanged:
                                                    (isSelected) {
                                                  onSelectionChanged(
                                                    order.id,
                                                    isSelected,
                                                  );
                                                },
                                                data: orders
                                                    .where(
                                                      (element) =>
                                                          element.rider !=
                                                              null &&
                                                          element.status ==
                                                              "processing",
                                                    )
                                                    .toList()[index],
                                                modal: true,
                                              );
                                            },
                                            separatorBuilder:
                                                (context, index) =>
                                                    const SizedBox(
                                              height: 10,
                                            ),
                                            itemCount: orders
                                                .where((element) {
                                                  return element.rider !=
                                                          null &&
                                                      element.status ==
                                                          "processing";
                                                })
                                                .toList()
                                                .length,
                                          ),
                                        ),
                              loading
                                  ? const SpinKitFadingCircle(
                                      color: accentColor,
                                    )
                                  : orders
                                          .where(
                                            (element) =>
                                                element.rider != null &&
                                                element.status == "delivered",
                                          )
                                          .isEmpty
                                      ? Center(
                                          child: SvgPicture.string(nodatafound),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 25,
                                          ),
                                          child: ListView.separated(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            scrollDirection: Axis.vertical,
                                            itemBuilder: (context, index) {
                                              final order = orders
                                                  .where(
                                                    (element) =>
                                                        element.rider != null &&
                                                        element.status ==
                                                            "delivered",
                                                  )
                                                  .toList()[index];
                                              final isSelected =
                                                  selectedStates[order.id] ==
                                                          null
                                                      ? false
                                                      : true;
                                              return OrderCard(
                                                isSelected: isSelected,
                                                data: order,
                                                modal: true,
                                                onSelectionChanged:
                                                    (isSelected) {
                                                  onSelectionChanged(
                                                    order.id,
                                                    isSelected,
                                                  );
                                                },
                                              );
                                            },
                                            separatorBuilder:
                                                (context, index) =>
                                                    const SizedBox(
                                              height: 10,
                                            ),
                                            itemCount: orders
                                                .where((element) {
                                                  return element.rider !=
                                                          null &&
                                                      element.status ==
                                                          "delivered";
                                                })
                                                .toList()
                                                .length,
                                          ),
                                        ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),